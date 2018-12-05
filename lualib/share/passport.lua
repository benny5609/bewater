local cluster = require "skynet.cluster"

local M = {}
setmetatable(M, {__index = function(t, k)
    local v = rawget(t, k)
    if v then
        return v
    else
        return function(...)
            return cluster.call("share", "passport", k, ...)
        end
    end
end})
return M
