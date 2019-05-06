local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local rmsg      = require "bw.share.rmsg"
local svr       = require "def.svr"
bewater.start(rmsg, function()
    rmsg.start({
        id_producer = function()
            return skynet.call(svr.ID_PRODUCER, "lua", "create")
        end,
        notify = function(uid)
            skynet.send(svr.USER, "lua", "notify", uid, "rmsg", "fetch")
        end,
    })
end)
