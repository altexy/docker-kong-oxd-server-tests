local oxd = require "oxdweb"

-- we don't store our token in lrucache - we don't want it be pushed out
local access_token
local access_token_expire = 0
local EXPIRE_DELTA = 10

local PLUGINNAME = "demo plugin"


local lrucache = require "resty.lrucache"
-- it can be shared by all the requests served by each nginx worker process:
local token_cache, err = lrucache.new(1000)  -- allow up to 1000 items in the cache
if not token_cache then
    return error("failed to create the cache: " .. (err or "unknown"))
end

return function(conf)
    kong.log("demo plugin access phase")

    local authorization = ngx.var.http_authorization
    local token
    if authorization and #authorization > 0 then
        local from, to, err = ngx.re.find(authorization, "\\s*[Bb]earer\\s+(.+)", "jo", nil, 1)
        if from then
            token = authorization:sub(from, to)
        end
    end

    if not token then
        kong.log("No token")
        return kong.response.exit(401)
    end

    local now = ngx.now()
    print(now)
    print(access_token_expire)
    if not access_token  or access_token_expire < now + EXPIRE_DELTA then
        access_token_expire = access_token_expire + EXPIRE_DELTA -- avoid multiple token requests
        local response = oxd.get_client_token(
            conf.oxd_http_url,
            {
                client_id = conf.client_id,
                client_secret = conf.client_secret,
                scope = "openid profile email",
                op_host = conf.op_server,
            }
        )

        local status = response.status
        local data = response.data

        if not status or #status == 0 or status == "error" or not data then
            access_token = nil
            access_token_expire = 0
            kong.log.err(PLUGINNAME .. ": Failed to get access token")
            return kong.response.exit(500)
        end

        access_token = data.access_token
        if data.expires_in then
            access_token_expire = ngx.now() + data.expires_in
        else
            -- use once
            access_token_expire = 0
        end
    end

    local response, stale_data = token_cache:get(token)
    if not response or stale_data then

        response = oxd.introspect_access_token(
            conf.oxd_http_url,
            {
                oxd_id = conf.oxd_id,
                access_token = token,
            },
            access_token
        )

        local status = response.status
        data = response.data

        if not status or #status == 0 or status == "error"  or not data then
            kong.log.err(PLUGINNAME .. ": Failed to register client")
            -- TODO shall we cache negative response?
            return kong.response.exit(401)
        end

        if data.exp and data.iat then
            token_cache:set(token, response, data.iat + data.exp - EXPIRE_DELTA)
        else
            kong.log.err(PLUGINNAME .. ": missed exp or iat fields")
            -- TODO what we must do?
        end
    end

    -- TODO implement scope expressions
end
