local Skynet = require "skynet"
local Util = require "util"

local addrs = {} -- mode -> service

local CMD = {}
function CMD.add_mode(mode, max_time, max_range)
    assert(not addrs[mode])
    addrs[mode] = Skynet.newservice("battle/match")
    Skynet.call(addrs[mode], "lua", "init", mode, max_time, max_range)
end

function CMD.match(mode, uid, value, agent)
    local addr = assert(addrs[mode])
    Skynet.call(addr, "lua", "start", uid, value, agent)
end

function CMD.reconnect(mode, uid, agent)
    local addr = assert(addrs[mode])
    Skynet.call(addr, "lua", "reconnect", uid, agent)
end

function CMD.cancel(mode, uid)
    local addr = assert(addrs[mode])
    Skynet.call(addr, "lua", "cancel", uid)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
end)
