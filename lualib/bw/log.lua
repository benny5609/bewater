local skynet = require "skynet"
local util = require "bw.util"

local tostring = tostring
local select   = select

local function log_format(...)
    local n = select("#",...)
    local out = {}
    local v_str
    for i=1,n do
        local v = select(i,...)
        if type(v) == "table" then
            v_str = "table:" .. util.serialize_table(v)
        else
            v_str = tostring(v)
        end

        table.insert(out, v_str)
    end
    return table.concat(out," ")
end

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, string.format(fmt, ...))
    end
end

function M.print(sys)
    return function(...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, log_format(...))
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
