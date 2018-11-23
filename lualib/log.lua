local Skynet = require "skynet"

local tostring = tostring
local select   = select

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        Skynet.send(".logger", "lua", "trace", Skynet.self(), sys, string.format(fmt, ...))
    end
end

function M.print(sys)
    return function(...)
        local args = {}
        for i = 1, select('#', ...) do
            args[i] = tostring(select(i, ...))
        end
        local str = table.concat(args, " ")
        Skynet.send(".logger", "lua", "trace", Skynet.self(), sys, str)
    end
end

function M.player(uid)
    return function(fmt, ...)
        Skynet.send(".logger", "lua", "player", Skynet.self(), uid, string.format(fmt, ...))
    end
end

function M.sighup()
    Skynet.send(".logger", "lua", "register_sighup", Skynet.self())
end

return M
