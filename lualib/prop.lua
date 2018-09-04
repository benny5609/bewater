local conf = require "conf"
local json = require "cjson"
local const = require "const"
local util = require "util"

local M = {}
local props = {}
function M.json(name)
    assert(name)
    if props[name] then
        return props[name]
    end
    local file = io.open(conf.workspace.."/script/def/prop/"..name..".json", "r")
    local str = file:read("*a")
    local prop = const(util.str2num(json.decode(str)))
    props[name] = prop
    return prop
end

return M
