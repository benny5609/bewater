local skynet = require "skynet.manager"
local cluster = require "skynet.cluster"

local M = {}
function M.auto(count)
    return cluster.call("share", "autoid", "auto", count)
end
return M
