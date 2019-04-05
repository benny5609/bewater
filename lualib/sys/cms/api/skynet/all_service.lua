local skynet    = require "skynet"

local function debug_call(addr, cmd, ...)
    return skynet.call(addr, "debug", cmd, ...)
end
return function()
    local list = {}
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        addr = string.gsub(addr, ':', "0x")
        local mem = debug_call(addr, "MEM")
        --[[if mem < 1024 then
            mem = math.floor(mem).." Kb"
        else
            mem = math.floor(mem/1024).." Mb"
        end]]
        local stat = debug_call(addr, "STAT")
        --v.address = skynet.address(addr)
        table.insert(list, {
            addr    = addr,
            desc    = desc,
            mem     = mem//1,
            task    = stat.task,
            mqlen   = stat.mqlen,
        })
    end

    return {
        list = list
    }
end
