local skynet    = require "skynet"
local rmsg      = require "bw.share.rmsg"
local util      = require "bw.util"
local log       = require "bw.log"

return function()
    local mid = 10000
    local uid = 101
    rmsg.start({
        id_producer = function()
            mid = mid + 1
            return mid
        end
    })

    rmsg.broadcast(0x1001, {a = "broadcast before", b = {cc = 1, dd = 2}})

    skynet.sleep(10)

    local time = skynet.time()

    rmsg.push(uid, 0x1000, {a = "hello", b = {cc = 1, dd = 2}})
    rmsg.broadcast(0x1001, {a = "broadcast", b = {cc = 1, dd = 2}})
    rmsg.push(uid, 0x1000, {a = "hello2", b = {cc = 1, dd = 2}})

    local list = rmsg.fetch(uid, time)
    util.printdump(list)

    rmsg.process(uid, list[1].mid, 0)
    rmsg.process(uid, list[3].mid, 0x0002)
    util.printdump(rmsg.fetch(uid, time))
end
