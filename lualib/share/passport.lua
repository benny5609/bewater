local skynet  = require "skynet.manager"
local cluster = require "skynet.cluster"

local M = {}
function M.create(uid)
    return cluster.call("share", "passport", "create", uid)
end

function M.get_uid(passport)
    return cluster.call("share", "passport", "get_uid", passport)
end

function M.get_passport(uid)
    return cluster.call("share", "passport", "get_passport", uid)
end

return M
