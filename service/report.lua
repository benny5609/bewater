-- 向monitor节点报告本节点性能，状态等(已废置)
--
local Skynet    = require "skynet"
local Cluster   = require "skynet.cluster"
local Info      = require "util.clusterInfo"
local Conf      = require "Conf"
local Util      = require "util"
local Log       = require "log"
local print     = Log.print("report")

require "bash"

local function send(...)
    print("send", Conf.clustername.monitor, ...)
    Cluster.send("monitor", "svr", ...)
end

local function call(...)
    print("call", Conf.clustername.monitor, ...)
    Cluster.call("monitor", "svr", ...)
end

local name = Info.clustername
local addr = Conf.cluster[name]

local CMD = {}
function CMD.start()
    Util.try(function()
        call("node_start", name, addr, Conf.proj, Info.pnet_addr, Info.inet_addr,
            Info.pid, string.format("%s:%s", Conf.webconsole.host, Conf.webconsole.port))
        Cluster.call("share", "svr", "node_start", name, addr) -- 向share上报集群配置
    end)
    Skynet.fork(function()
        while true do
            CMD.ping()
            Skynet.sleep(100)
        end
    end)
end

function CMD.ping()
    if not Info.pid then
        send("node_ping", addr, 0, 0)
        return
    end

    local profile = Info.profile
    Util.try(function()
        send("node_ping", addr, profile.cpu, profile.mem)
    end)
end

function CMD.stop()
    Util.try(function()
        send("node_stop", addr)
    end)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
end)
