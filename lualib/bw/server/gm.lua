local skynet        = require "skynet"
local log           = require "bw.log"
local schedule      = require "bw.schedule"
local bewater       = require "bw.bewater"
local date_helper   = require "bw.util.date_helper"

require "skynet.cluster"

local trace = log.trace("gm")

local skynet_cmd = {}
function skynet_cmd.gc()
    skynet.call(".launcher", "lua", "GC")
end

function skynet_cmd.call(addr, ...)
    addr = tonumber(addr, 16) or assert(addr)
    print("call", addr, ...)
    return skynet.call(addr, "lua", ...)
end

function skynet_cmd.list()
    local list = {}
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = skynet.call(addr, "debug", "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = skynet.call(addr, "debug", "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = skynet.address(addr)
    end
    table.sort(list, function(a, b)
        return a.addr < b.addr
    end)
    local str = ""
    for i, v in ipairs(list) do
        str = str .. string.format("地址:%s 内存:%s 消息队列:%s 请求量:%s 启动命令:%s\n",
            v.addr, v.mem, v.mqlen, v.task, v.desc)
    end
    return str
end

function skynet_cmd.alert()
    error("test alert")
end

function skynet_cmd.time(...)
    trace("gm time")
    local args = table.pack(...)
    local t = {}
    for i = 1, #args, 2 do
        t[args[i]] = tonumber(args[i+1])
    end
    local cur = schedule.changetime(t)
    return string.format("时间修改至 %s", date_helper.format(cur))
end
local gmcmd = {
    skynet = skynet_cmd,
}
local M = {}
function M.add_gmcmd(modname, gmcmd_path)
    gmcmd[modname] = require(gmcmd_path)
    assert(type(gmcmd[modname]) == "table", modname)
end

function M.run(modname, cmd, ...)
    modname = string.lower(modname)
    cmd = string.lower(cmd)
    local mod = gmcmd[modname]
    if not mod then
        return string.format("模块[%s]未初始化", modname)
    end
    local f = mod[cmd]
    if not f then
        return string.format("GM指令[%s][%s]不存在", modname, cmd)
    end
    local args = {...}
    local ret
    if not bewater.try(function()
        ret = f(table.unpack(args))
    end) then
        return "服务器执行TRACEBACK了"
    end
    return ret or "执行成功"
end

function M.start(cmds)
    for k, v in pairs(cmds) do
        gmcmd[k] = v
    end
end

return M


