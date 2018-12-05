-- 向monitor节点报告本节点性能，状态等(已废置)
--
local skynet    = require "skynet"
local cluster   = require "skynet.cluster"
local info      = require "util.clusterinfo"
local conf      = require "conf"
local bewater   = require "bewater"
local log       = require "log"
local print     = log.print("report")

require "bash"

local function send(...)
    print("send", conf.clustername.monitor, ...)
    cluster.send("monitor", "svr", ...)
end

local function call(...)
    print("call", conf.clustername.monitor, ...)
    cluster.call("monitor", "svr", ...)
end

local name = info.clustername
local addr = conf.cluster[name]

local CMD = {}
function CMD.start()
    bewater.try(function()
        call("node_start", name, addr, conf.proj, info.pnet_addr, info.inet_addr,
            info.pid, string.format("%s:%s", conf.webconsole.host, conf.webconsole.port))
        cluster.call("share", "svr", "node_start", name, addr) -- 向share上报集群配置
    end)
    skynet.fork(function()
        while true do
            CMD.ping()
            skynet.sleep(100)
        end
    end)
end

function CMD.ping()
    if not info.pid then
        send("node_ping", addr, 0, 0)
        return
    end

    local profile = info.profile
    bewater.try(function()
        send("node_ping", addr, profile.cpu, profile.mem)
    end)
end

function CMD.stop()
    bewater.try(function()
        send("node_stop", addr)
    end)
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        bewater.ret(f(...))
    end)
end)
