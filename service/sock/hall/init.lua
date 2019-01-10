local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local protobuf  = require "bw.protobuf"
local log       = require "bw.log"
local env       = require "env"
local sessions  = require "sessions"

local trace = log.trace("hall")

local server_path, role_path, visitor_path = ...
env.SERVER  = assert(server_path)
env.ROLE    = assert(role_path)
env.VISITOR = assert(visitor_path)

local gate
local server = require(server_path)

local CMD = {}
function CMD.start(param)
    env.PROTO       = assert(param.proto)
    env.PORT        = assert(param.port)
    env.NODELAY     = assert(param.nodelay)
    env.MAXCLIENT   = assert(param.maxclient)
    env.PRELOAD     = param.preload or 10

    protobuf.register_file(env.PROTO)

    skynet.call(gate, "lua", "open", param)
    if server.start then
        server.start()
    end
    trace("hall start")
end

function CMD.stop()
    sessions.close_all()
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
    env.GATE = gate
end)
