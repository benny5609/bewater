local Cluster = require "skynet.cluster"

local M = {}
setmetatable(M, {__index = function(t, k)
    local v = rawget(t, k)
    if v then
        return v
    else
        return function(...)
            return Cluster.call("share", "passport", k, ...)
        end
    end
end})
return M
