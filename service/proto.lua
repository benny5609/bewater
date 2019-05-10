local skynet = require "skynet.manager"
local bewater = require "bw.bewater"

local CMD = {}
function CMD.get_protobuf_env()
    return debug.getregistry().PROTOBUF_ENV
end
function CMD.register_file(path)
    local protobuf_c = require "protobuf.c"
    debug.getregistry().PROTOBUF_ENV = protobuf_c._env_new()
    local protobuf = require "bw.protobuf"
    protobuf.register_file(path)
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_,cmd, ...)
        local f = assert(CMD[cmd])
        bewater.ret(f(...))
    end)

end)
