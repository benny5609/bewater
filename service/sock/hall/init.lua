local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local log       = require "bw.log"
local env       = require "env"
local sessions  = require "sessions"
local agents    = require "agents"

local trace = log.trace("hall")

local server_path, role_path = ...
env.SERVER  = assert(server_path) -- 服务逻辑(xxx.xxxserver)
env.ROLE    = assert(role_path)   -- 玩家逻辑(xxx.xxxrole)

local gate
local server = require(server_path)

local CMD = {}
function CMD.start(param)
    env.PROTO       = assert(param.proto)
    env.PORT        = assert(param.port)
    env.NODELAY     = assert(param.nodelay)
    env.MAXCLIENT   = assert(param.maxclient)
    env.PRELOAD     = param.preload or 10
    
    skynet.call(gate, "lua", "open", param)
    if server.start then
        server.start()
    end
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
    env.GATE = gate
end)
