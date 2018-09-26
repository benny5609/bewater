-- 向share节点上报集群配置
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local conf = require "conf"

local M = {}
function M.init()
    local name = conf.clustername
    local addr = conf.cluster[name]
    cluster.call("share", "svr", "node_start", name, addr) -- 向share上报集群配置
end
return M

