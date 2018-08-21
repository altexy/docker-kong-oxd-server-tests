local oxd = require "oxdweb"

-- TODO expiration
local access_token

local PLUGINNAME = "demo plugin"

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

    if not access_token then
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

        if not status or #status == 0 or status == "error" or not response.data then
            kong.log.err(PLUGINNAME .. ": Failed to get access token")
            return kong.response.exit(500)
        end

        access_token = response.data.access_token
    end

    local response = oxd.introspect_access_token(
        conf.oxd_http_url,
        {
            oxd_id = conf.oxd_id,
            access_token = token,
        },
        access_token
    )

    local status = response.status

    if not status or #status == 0 or status == "error"  or not response.data then
        kong.log.err(PLUGINNAME .. ": Failed to register client")
        return kong.response.exit(401)
    end

    -- just allow everything
end
