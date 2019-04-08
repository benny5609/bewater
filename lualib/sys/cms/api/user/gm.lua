local gm     = require "bw.gm"
local function ret(output)
    local time_str = string.format("[%s] ", os.date("%Y-%m-%d %H:%M:%S"))
    return {
        log = time_str .. output
    }
end
return function(_, data)
    local args = {}
    for arg in string.gmatch(data.cmd, "[^ ]+") do
        table.insert(args, arg)
    end
    local modname = args[1]
    local cmd = args[2]
    if not modname then
        return ret(string.format("模块%s不存在", args[1]))
    end
    if not cmd then
        return ret(string.format("命令%s不存在", args[2]))
    end
    table.remove(args, 1)
    table.remove(args, 1)
    return ret(gm.run(modname, cmd, table.unpack(args)))
end
