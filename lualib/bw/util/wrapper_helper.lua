local conf = require "conf"
local json = require "cjson.safe"
local bash = require "bw.bash"
bash = bash.bash

local _settings

local function save_settings()
    local file = io.open(conf.workspace.."/data/wrapper_settings.json", "w+")
    file:write(json.encode(_settings))
    file:close()
end

local M = {}
function M.get_settings()
    if _settings then
        return _settings
    end
    local file = io.open(conf.workspace.."/data/wrapper_settings.json", "r")
    if not file then
        return {}
    end
    local str = file:read("*a")
    _settings = json.decode(str) or {}
    file:close()
    return _settings
end

function M.get(k)
    return M.get_settings()[k]
end

function M.set(k, v)
    assert(k)
    assert(v.name)
    local settings = M.get_settings()
    settings[k] = v
    save_settings() 
end

function M.remove_settings(names)
    assert(names)
    local settings = M.get_settings()
    for k in string.gmatch(names, "([^ ]+)") do
        settings[k] = nil
    end
    save_settings()
end

function M.get_version_list(name)
    local settings = M.get_settings()
    local setting = settings[name]
    local cur
    local list = {}
    local ret = bash("ls --full-time %s/assets", setting.path)
    for str in string.gmatch(ret, "[^\n]+") do
        if string.len(str) > 10 then
            local version = string.match(str, "[^ ]+$")
            local time = string.match(str, "(%d+-%d+-%d+ %d+:%d+:%d+)")
            if string.match(str, "current") then
                cur = version
            else
                table.insert(list, {
                    version = version,
                    time = time,
                }) 
            end
        end
    end
    if cur then
        for _, v in pairs(list) do
            if cur == v.version then
                v.LAY_CHECKED = true
            end
        end
    end
    table.sort(list, function(a, b)
        return M.to_version_num(a.version) > M.to_version_num(b.version) 
    end)
    return list
end

function M.get_current(name)
    local list = M.get_version_list(name)
    for _, v in pairs(list) do
        if v.LAY_CHECKED then
            return v.version
        end
    end
end

function M.to_version_num(version)
    assert(type(version) == "string")
    local v1, v2, v3 = string.match(version, "(%d+)%.(%d+)%.(%d+)")
	if not v1 then
        return
    end
	return v1*1000000 + v2*1000 + v3
end

function M.to_version_str(num)
    assert(type(version) == "number")
    return string.format("%d.%d.%d", num//1000000, num%1000000//1000, num%1000)
end


return M
