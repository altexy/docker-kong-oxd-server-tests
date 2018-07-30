local oxd = require "oxdweb"

local _M = {}

local PLUGINNAME = "test1"
_M.PLUGINNAME = PLUGINNAME

--- Register OP client using oxd setup_client
-- @param conf: plugin global values
-- @return response: response of setup_client
function _M.client_setup(conf)
    ngx.log(ngx.DEBUG, PLUGINNAME .. ": Registering on oxd ...")

    -- ------------------Register Site----------------------------------
    local setupClientRequest = {
        scope = { "openid", "uma_protection" },
        op_host = conf.op_server,
        authorization_redirect_uri = "https://client.example.com/cb",
        client_name = "test1 plugin",
        grant_types = { "client_credentials" }
    }

    local setupClientResponse = oxd.setup_client(conf.oxd_http_url, setupClientRequest)

    local status = setupClientResponse.status

    print(status)

    if not status or #status == 0 or status == "error" then
        kong.log.err(PLUGINNAME .. ": Failed to register client")
        return false
    end

    conf.oxd_id = setupClientResponse.data.oxd_id
    conf.client_id = setupClientResponse.data.client_id
    conf.client_secret = setupClientResponse.data.client_secret
    return true
end

return _M
