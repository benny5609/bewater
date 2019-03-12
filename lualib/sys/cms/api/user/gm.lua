local gm     = require "bw.gm"
local function ret(output)
    local time_str = string.format("[%s] ", os.date("%Y-%m-%d %H:%M:%S"))
    return {
        output = time_str .. output
    }
end
return function(_, data)
    local args = {}
    for arg in string.gmatch(data.gm, "[^ ]+") do
        table.insert(args, arg)
    end
    local modname = args[1]
    local cmd = args[2]
    if not modname or not cmd then
        return ret("格式错误")
    end
    table.remove(args, 1)
    table.remove(args, 1)
    return ret(gm.run(modname, cmd, table.unpack(args)))
end
