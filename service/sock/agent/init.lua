local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local protobuf  = require "bw.protobuf"
local users     = require "users"
local env       = require "env"

local CMD = {}
function CMD.start(param)
    env.ROLE    = assert(param.role_path)
    env.PROTO   = assert(param.proto)
    env.GATE    = assert(param.gate)

    protobuf.register_file(env.PROTO)
end

function CMD.open(fd, uid)
    skynet.call(env.GATE, "lua", "forward", fd)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        bewater.ret(f(...))
    end)
end)


