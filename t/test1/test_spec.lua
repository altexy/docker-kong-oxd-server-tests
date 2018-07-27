local utils = require"test_utils"
local sh, stdout, stderr, sleep, sh_ex =
    utils.sh, utils.stdout, utils.stderr, utils.sleep, utils.sh_ex
local pl_path = require"pl.path"

local host_git_root = os.getenv"HOST_GIT_ROOT"
local git_root = os.getenv"GIT_ROOT"

local test_name = "test1" -- should be in sync with file structure

local docker_compose_prefix = "docker-compose -f " .. git_root .. "/t/" ..test_name .."/docker-compose.yml "
local docker_compose = function(suffix)
    sh(docker_compose_prefix .. suffix)
end

local kong_container_name = test_name .. "_kong_1"


test("kong test", function()
    docker_compose("up -d kong-database")

    -- TODO replace with more stable script
    sleep(5) -- lets postgress chance to start
    --docker_compose("logs kong-database")

    -- start it as foreground to get a chance to finish
    docker_compose("up kong-migration > /dev/null")

    docker_compose("up -d oxd-mock")

    docker_compose("up -d kong backend")

    -- TODO replace with more stable solution
    sleep(5) -- lets kong chance to start

    local print_logs = true
    finally(function()
        if print_logs then
            docker_compose("logs kong")
            docker_compose("logs oxd-mock")
        end

        docker_compose("down -v") -- comment this out if you need to see logs after errors
    end)

    -- create a Sevice
    local res, err = sh_ex(
        [[curl -i -sS -X POST --url http://localhost:8001/services/ --data 'name=test1-service' --data 'url=http://backend']]
    )

    -- create a Route
    local res, err = sh_ex(
        [[curl -i -sS -X POST  --url http://localhost:8001/services/test1-service/routes --data 'hosts[]=backend.com']]
    )

    -- test it works
    local res, err = sh_ex([[curl -i -sS -X GET --url http://localhost:8000/ --header 'Host: backend.com']])

    -- enable plugin for the Service
    local res, err = sh_ex([[
curl -i -sS -X POST  --url http://localhost:8001/services/test1-service/plugins/  --data 'name=test1' \
--data "config.hide_credentials=true" \
--data "config.op_server=stub" \
--data "config.oxd_http_url=http://oxd-mock"]]
    )

    -- test it works
    local res, err = sh_ex([[curl -i -sS  -X GET --url http://localhost:8000/ --header 'Host: backend.com']])

    print_logs = false
end)
