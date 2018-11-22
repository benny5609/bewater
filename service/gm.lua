local Skynet        = require "skynet"
local Log           = require "log"
local Schedule      = require "schedule"
local Util          = require "util"
local DateHelper    = require "util.date_helper"

local trace = Log.trace("gm")

local skynet_cmd = {}
local gmcmd = {
    skynet = skynet_cmd,
}

local CMD = {}
function CMD.add_gmcmd(modname, gmcmd_path)
    gmcmd[modname] = require(gmcmd_path)
end

function CMD.run(modname, cmd, ...)
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
    if not Util.try(function()
        ret = f(table.unpack(args))
    end) then
        return "服务器执行TRACEBACK了"
    end
    return ret or "执行成功"
end

local hotfix_addrs = {}
function CMD.reg_hotfix(addr)
    --trace("reg_hotfix:%s", addr)
    hotfix_addrs[addr] = true
end

function CMD.unreg_hotfix(addr)
    hotfix_addrs[addr] = nil
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
end)

function skynet_cmd.gc()
    Skynet.call(".launcher", "lua", "GC")
end

function skynet_cmd.call(addr, ...)
    addr = tonumber(addr, 16) or assert(addr)
    print("call", addr, ...)
    return Skynet.call(addr, "lua", ...)
end

function skynet_cmd.list()
    local list = {}
    local all = Skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = Skynet.call(addr, "debug", "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = Skynet.call(addr, "debug", "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = Skynet.address(addr)
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

function skynet_cmd.hotfix()
    trace("gm hotfix")
    for addr, _ in pairs(hotfix_addrs) do
        Skynet.send(addr, "lua", "hotfix")
    end
end

function skynet_cmd.publish(nodename)
    trace("publish:%s", nodename)
    Skynet.newservice("publish", nodename)
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
    local cur = Schedule.changetime(t)
    return string.format("时间修改至 %s", DateHelper.format(cur))
end

