local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local rmsg      = require "bw.share.rmsg"
local sname     = require "sname"
bewater.start(rmsg, function()
    rmsg.start({
        id_producer = function()
            return skynet.call(sname.ID_PRODUCER, "lua", "create")
        end,
        notify = function(uid)
            skynet.send(sname.USER, "lua", "notify", uid, "rmsg", "fetch")
        end,
    })
end)
