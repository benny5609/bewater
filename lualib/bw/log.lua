local skynet = require "skynet"

local tostring = tostring
local select   = select

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, string.format(fmt, ...))
    end
end

function M.print(sys)
    return function(...)
        local args = {}
        for i = 1, select('#', ...) do
            args[i] = tostring(select(i, ...))
        end
        local str = table.concat(args, " ")
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, str)
    end
end


function M.role(uid, sys)
    assert(uid)
    assert(sys)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "role", skynet.self(), uid, sys, string.format(fmt, ...))
    end
end

function M.error(fmt, ...)
    skynet.send(".logger", "lua", "error", skynet.self(), string.format(fmt, ...))
end

function M.sighup()
    skynet.send(".logger", "lua", "register_sighup", skynet.self())
end

return M
