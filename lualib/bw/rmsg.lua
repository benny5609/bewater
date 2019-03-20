--  reliable message
--  可靠消息
local bewater   = require "bw.bewater"
local factory   = require "bw.orm.factory"
local log       = require "bw.log"

local autoid -- function create mid

local broadcast_list = {}, -- 广播
local queues = {},         -- uid:队列

local M = {}
function M.start(handler)
    autoid = assert(handler.autoid)
end

function M.get_broadcast_list()
    return broadcast_list
end

function M.get_queues()
    return queues
end

function M.get_queue(uid)
    local queue = queues[uid]
    if not queue then
        queue = {}
        queues[uid] = queue
    end
    return queue
end

function M.get_msg(uid, mid)
    local queue = M.get_queue(uid)
    for i = #queue, 1, -1 do
        local msg = queue[i]
        if msg.mid == mid then
            return msg
        end
    end
end

-- 处理结果
function M.process(uid, mid, err)
    local msg = M.get_msg(uid, mid)
    if not msg then
        log.error("[rmsg] msg not exist, uid:%s, mid:%s, state:%s", uid, mid, state)
        return
    end
    msg.err = err
end

function M.push(uid, op, args)
    assert(uid)
    assert(op)
    local queue = M.get_queue(uid)
    local msg = factory.create("rmsg", {
        mid = autoid(),
        op = op,
        args = json.encode(args or {}),
        err = -1
    })
end

return M
