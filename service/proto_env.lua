local Skynet = require "skynet.manager"
local Util = require "util"

local CMD = {}
function CMD.get_protobuf_env()
    return debug.getregistry().PROTOBUF_ENV
end
function CMD.register_file(path)
    local protobuf_c = require "protobuf.c"
    debug.getregistry().PROTOBUF_ENV = protobuf_c._env_new()
    local protobuf = require "protobuf"
    protobuf.register_file(path)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_,cmd, ...)
        local f = assert(CMD[cmd])
        Util.ret(f(...))
    end)

end)
