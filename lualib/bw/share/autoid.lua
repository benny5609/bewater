local cluster = require "skynet.cluster"

local M = {}
function M.create(count)
    return cluster.call("share", "autoid", "create", count)
end
return M
