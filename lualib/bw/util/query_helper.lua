local conf = require "conf"
local json = require "cjson.safe"
local bash = require "bw.bash"
bash = bash.bash

local M = {}
function M.get_settings()
    local file = io.open(conf.workspace.."/data/query_settings.json", "r")
    if not file then
        return {}
    end
    local str = file:read("*a")
    file:close()
    return json.decode(str) or {}
end

function M.save_settings(settings)
    bash("mkdir -p %s/data", conf.workspace)
    local file = io.open(conf.workspace.."/data/query_settings.json", "w+")
    file:write(json.encode(settings))
    file:close()
end

return M
