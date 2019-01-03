local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local log       = require "bw.log"
local env       = require "env"
local sessions  = require "sessions"
local agents    = require "agents"

local trace = log.trace("hall")

local gate
local server

local CMD = {}
function CMD.start(param)
    env.SERVER = assert(param.server)
    env.ROLE = assert(param.role)
    server = require(param.server)
end

function CMD.stop()

end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, arg1, arg2, ...)
        if arg1 == "socket" then
            local f = assert(sessions[arg2], arg2)
            f(...)
            return
        elseif CMD[arg1] then
            bewater.ret(CMD[arg1](arg2, ...))
        else
            local f = assert(server[arg1], arg1)
            bewater.ret(f(arg2, ...))
        end
    end)

    gate = skynet.newservice("gate")
    env.gate = gate
end)
