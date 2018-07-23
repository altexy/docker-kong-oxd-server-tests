-- this function should be called in context of content_by_lua directive
-- require nginx with single worker process

local cjson = require"cjson"

local index

-- TODO add check that Authorization header is present with valid token

-- model is an array where every element has structure below:
-- expect: expected oxd-https-extentions endpoint
-- data: body to response, will be conversted into JSON
return function(model)
    index = index and index + 1 or 1
    local item = model[index]

    local path = ngx.var.uri
    if path ~= item.expect then
        return nil, { status = 400, message = "Expect: " .. item.expect .. " Got: " .. path }
    end

    ngx.header.content_type = 'application/json; charset=UTF-8'
    local json = cjson.encode(item.response)
    ngx.say(json)
end

