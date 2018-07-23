local utils = require "kong.tools.utils"
local helper = require "kong.plugins.test1.helper"

--- Check op_server_validator is must https and not empty
-- @param given_value: Value of op_server_validator
-- @param given_config: whole config values including op_server_validator
local function op_server_validator(given_value, given_config)
    kong.log.debug("op_server_validator: given_value:" .. given_value)

-- TODO allow http for test env
--    if not (string.sub(given_value, 0, 8) == "https://") then
--        ngx.log("op_server must be 'https'")
--        return false, "op_server must be 'https'"
--    end

    return true
end

--- Check user valid UUID
-- @param anonymous: anonymous consumer id
local function check_user(anonymous)
    if anonymous == "" or utils.is_valid_uuid(anonymous) then
        return true
    end

    return false, "the anonymous user must be empty or a valid uuid"
end

return {
    no_consumer = true,
    fields = {
        hide_credentials = { type = "boolean", default = false },
        oxd_id = { type = "string" },
        op_server = { required = true, type = "string", func = op_server_validator },
        oxd_http_url = { required = true, type = "string" },
        anonymous = {type = "string", default = "", func = check_user}
    },
    self_check = function(schema, plugin_t, dao, is_updating)
        local oxd_id = plugin_t.oxd_id
        kong.log.debug("oxd_id: " .. tostring(oxd_id))
        if oxd_id and #oxd_id > 0 then
            return true
        end

        return helper.client_setup(plugin_t), "Failed to register API on oxd server (make sure oxd server is running on oxd_host specified in configuration)"
    end
}