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
    env.HALL    = assert(param.hall)

    protobuf.register_file(env.PROTO)

    skynet.fork(function()
        while true do
            users.check_timeout()
            skynet.sleep(100)
        end
    end)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, arg1, arg2, arg3, ...)
        local f = CMD[arg1] or users[arg1]
        if f then
            bewater.ret(f(arg2, arg3, ...))
        elseif type(arg1) == "number" then
            local uid = arg1
            local user = users.get_user(uid)
            assert(user, uid)
            local role = assert(user.role, uid)
            local module = assert(role[arg2], arg2)
            if type(module) == "function" then
                bewater.ret(module(role, arg3, ...))
            else
                bewater.ret(module[arg3](module, ...))
            end
        end
    end)
end)


