local Skynet = require "skynet.manager"
local Cluster = require "skynet.cluster"

local M = {}
function M.create(count)
    return Cluster.call("share", "autoid", "create", count)
end
return M
