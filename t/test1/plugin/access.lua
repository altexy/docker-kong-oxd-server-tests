local helper = require "kong.plugins.test1.helper"

return function(conf)
    kong.log(helper.PLUGINNAME, " plugin access phase")
    -- just allow everything
end
