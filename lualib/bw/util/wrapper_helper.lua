local conf = require "conf"
local json = require "cjson.safe"
local bash = require "bw.bash"
bash = bash.bash

local function save_settings(settings)
    bash("mkdir -p %s/data", conf.workspace)
    local file = io.open(conf.workspace.."/data/wrapper_settings.json", "w+")
    file:write(json.encode(settings))
    file:close()
end

local M = {}
function M.get_settings()
    local file = io.open(conf.workspace.."/data/wrapper_settings.json", "r")
    if not file then
        return {}
    end
    local str = file:read("*a")
    file:close()
    return json.decode(str) or {}
end

function M.get_doc(name)
    local setting = M.get(name)
    local file = io.open(setting.path.."/version_doc.json", "r")
    if not file then
        return {}
    end
    local str = file:read("*a")
    file:close()
    return json.decode(str) or {}
end

function M.save_doc(name, tbl)
    local setting = M.get(name)
    local file = io.open(setting.path.."/version_doc.json", "w+")
    file:write(json.encode(tbl))
    file:close()
end

function M.get(k)
    return M.get_settings()[k]
end

function M.set(k, v)
    assert(k)
    assert(v.name)
    local settings = M.get_settings()
    settings[k] = v
    save_settings(settings) 
end

function M.remove_settings(names)
    assert(names)
    local settings = M.get_settings()
    for k in string.gmatch(names, "([^ ]+)") do
        settings[k] = nil
    end
    save_settings(settings)
end

function M.get_version_list(name)
    local settings = M.get_settings()
    local doc = M.get_doc(name)
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
                local v = doc[version] or {}
                table.insert(list, {
                    version = version,
                    time = time,
                    desc = v.desc,
                    git = v.git
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
