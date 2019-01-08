local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local protobuf  = require "bw.protobuf"
local users     = require "users"
local env       = require "env"

require "skynet.cluster"

local CMD = {}
function CMD.start(param)
    env.ROLE    = assert(param.role_path)
    env.PROTO   = assert(param.proto)
    env.GATE    = assert(param.gate)

    protobuf.register_file(env.PROTO)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd] or users[cmd], cmd)
        bewater.ret(f(...))
    end)
end)


