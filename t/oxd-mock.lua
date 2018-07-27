-- this function should be called in context of content_by_lua directive
-- require nginx with single worker process

local cjson = require"cjson"

local function read_file(path)
    local file = io_open(path, "rb") -- r read mode and b binary mode
    if not file then return nil, "Cannot open file: " .. path  end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end


local function get_body_data()
    -- explicitly read the req body
    ngx.req.read_body()

    local data = ngx.req.get_body_data()
    if not data then
        -- body may get buffered in a temp file:
        local filename = ngx.req.get_body_file()
        if not filename then
            print("no body found")
            return nil
        end
        -- this is really bad for performance
        data = check(500, read_file(filename)) -- body should be here
    end
    return data
end


-- TODO add check that Authorization header is present with valid token


local index = 0
-- model is an array where every element has structure below:
-- expect: expected oxd-https-extentions endpoint
-- data: body to response, will be conversted into JSON
-- callback: function to modify hardcoded response before send it to wire
return function(model)
    index = index + 1

    if index > #model then
        ngx.log(ngx.ERR, "scenario is finished")
        return ngx.exit(500)
    end

    if ngx.req.get_method() ~= "POST" then
        ngx.log(ngx.ERR, "expect POST method,  got: ", method)
        return ngx.exit(400)
    end

    local content_type = ngx.var.http_content_type
    if not content_type:find("application/json", 1, true) then
        ngx.log(ngx.ERR, "expect application/json cContent-Type,  got: ", content_type)
        return ngx.exit(400)
    end

    local body = get_body_data()
    local params = cjson.decode(body)

    local item = model[index]

    local required_fields = item.required_fields
    if required_fields then
        for i = 1, #required_fields do
            if not params[required_fields[i]] then
                ngx.log(ngx.ERR, "missed parameter: ", required_fields[i])
                return ngx.exit(400)
            end
        end
    end

    local path = ngx.var.uri
    if path ~= item.expect then
        ngx.log(ngx.ERR, "expect endpoint: ", item.expect, " got: ", path)
        return ngx.exit(400)
    end

    ngx.header.content_type = "application/json; charset=UTF-8"
    local response = item.response
    local response_callback = item.response_callback
    if response_callback then
        response = response_callback(response)
    end
    local json = cjson.encode(response)
    ngx.say(json)
end
