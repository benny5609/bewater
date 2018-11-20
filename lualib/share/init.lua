-- 向share节点上报集群配置
local Skynet = require "skynet"
local Cluster = require "skynet.cluster"
local Conf = require "conf"

local M = {}
function M.init()
    local name = Conf.clustername
    local addr = Conf.cluster[name]
    Cluster.call("share", "svr", "node_start", name, addr) -- 向share上报集群配置
end
return M

