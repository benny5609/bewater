local skynet    = require "skynet"
local conf      = require "conf"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local def       = require "def.def"

local export = {}
function export.js_module(str)
    return string.format("module.exports = %s;", str)
end

local function format_number(num, hex)
    return string.format(hex and "0x%.4x" or "%s", num)
end

local tab = "\t"
local header = "//此配置文件由服务器导出，请勿手动修改\n"

function export.js_obj(obj, depth, hex)
    depth = depth or 0
    local list = {}
    for k, v in pairs(obj) do
        list[#list+1] = k
    end
    table.sort(list, function(a, b)
        if type(a) == type(b) then
            return a < b
        else
            return type(a) == "number"
        end
    end)
    local str = ""
    str = str .. "{\n"
    for i, k in ipairs(list) do
        str = str .. string.rep(tab, depth + 1)
        if type(k) == "number" then
            str = str .. '[' .. format_number(k, hex) .. ']:'
        else
            str = str .. k .. ':'
        end
        local v = obj[k]
        if type(v) == "table" then
            str = str .. export.js_obj(v, depth + 1, hex)
        elseif type(v) == "number" then
            str = str .. format_number(v, hex)
        else
            str = str .. string.format('"%s"', v)
        end
        if i < #list then
            str = str .. ",\n"
        end
    end

    str = str .. "\n"
    str = str .. string.rep(tab, depth)
    str = str .. "}"
    return str
end

function export.opcode(path)
    local code2name = opcode.get_code2name()
    local map = {CODE = {}}
    for code, fullname in pairs(code2name) do
        local module = string.match(fullname, "^[^.]+")
        local name = string.match(fullname, "[^.]+$")
        map[module] = map[module] or {}
        map[module][name] = code
        map.CODE[code] = fullname
    end
    local str = export.js_obj(map, 0, true)
    local file = io.open(path or conf.workspace.."/data/opcode.js", "w+")
    file:write(header..export.js_module(str))
    file:close()
end

function export.errcode(path)
    local name2errcode = errcode.get_name2errcode()
    local map = {DESC = {}}
    for name, code in pairs(name2errcode) do
        map[name] = code
        map.DESC[code] = errcode.describe(code)
    end
    local str = export.js_obj(map, 0, true)
    local file = io.open(path or conf.workspace.."/data/errcode.js", "w+")
    file:write(header..export.js_module(str))
    file:close()
end

function export.def(path)
    skynet.error("export_def")
    local str = export.js_obj(def, 0)
    local file = io.open(path or conf.workspace.."/data/def.js", "w+")
    file:write(header..export.js_module(str))
    file:close()
end

return export
