local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.demo.access"

local handler = BasePlugin:extend()
-- handler.priority = 999

-- Your plugin handler's constructor. If you are extending the
-- Base Plugin handler, it's only role is to instanciate itself
-- with a name. The name is your plugin name as it will be printed in the logs.
function handler:new()
    handler.super.new(self, "demo")
end

function handler:access(config)
    -- Eventually, execute the parent implementation
    -- (will log that your plugin is entering this context)
    handler.super.access(self)

    return access(config)
end

return handler
