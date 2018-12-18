local skynet = require "skynet"
local util = require "util"
local layui = require "cms.layui"

local function debug_call(addr, cmd, ...)
    return skynet.call(addr, "debug", cmd, ...)
end
return function()
    local head = {"地址", "描述", "内存", "任务", "消息队列"}
    local tbl = {}
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        addr = string.gsub(addr, ':', "0x")
        local mem = debug_call(addr, "MEM")
        if mem < 1024 then
            mem = math.floor(mem).." Kb"
        else
            mem = math.floor(mem/1024).." Mb"
        end
        local stat = debug_call(addr, "STAT")
        --v.address = skynet.address(addr)
        table.insert(tbl, {
            addr,
            desc,
            mem,
            stat.task,
            stat.mqlen,
        })
    end

    return {
        content = layui.table(head, tbl)
    }
end
