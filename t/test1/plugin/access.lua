local helper = require "kong.plugins.test1.helper"
local oxd = require "oxdweb"


return function(conf)
    kong.log(helper.PLUGINNAME, " plugin access phase")

    local authorization = ngx.var.http_authorization
    local token
    if authorization and #authorization > 0 then
        token = ngx.re.match(authorization, "\\s*[Bb]earer\\s+(.+)", "jo")
    end

    if not token then
        kong.log("No token")
        return kong.response.exit(401)
    end

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
    local access_token = response.data.access_token

    if not status or #status == 0 or status == "error" then
        kong.log.err(PLUGINNAME .. ": Failed to get access token")
        return kong.response.exit(500)
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
    local access_token = response.data.access_token

    if not status or #status == 0 or status == "error" then
        kong.log.err(PLUGINNAME .. ": Failed to register client")
        return kong.response.exit(500)
    end



    -- just allow everything
end
