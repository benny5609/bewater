local skynet = require "skynet"
local gm     = require "gm"
local layui  = require "cms.layui"
local action = layui.action
local function ret(output)
    return {
        cb = {"output", layui.action.APPEND_VAL, output}
    }
end
return function(_, data)
    local time_str = string.format("[%s] ", os.date("%Y-%m-%d %H:%M:%S"))
    local args = {}
    for arg in string.gmatch(data.gm, "[^ ]+") do
        table.insert(args, arg)
    end
    local modname = args[1]
    local cmd = args[2]
    if not modname or not cmd then
        return ret(time_str.."格式错误")
    end
    table.remove(args, 1)
    table.remove(args, 1)
    local output = time_str..gm.run(modname, cmd, table.unpack(args))
    return ret(output)
end
