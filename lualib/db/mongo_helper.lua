local Skynet    = require "skynet"
local Sname     = require "sname"
local M = {}
setmetatable(M, {__index = function(t, k)
    local v = rawget(t, k)
    if v then
        return v
    else
        return function(...)
            return Skynet.call(Sname.MONGO, "lua", k, ...)
        end
    end
end})
return M
