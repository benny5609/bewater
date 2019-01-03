local skynet = require "skynet"
local bewater = require "bw.bewater"

local CMD = {}


skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        bewater.ret(f(...))
    end)
end)


