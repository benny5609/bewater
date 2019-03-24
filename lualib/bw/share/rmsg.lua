--  reliable message
--  可靠消息
local skynet    = require "skynet"
local json      = require "cjson.safe"
local factory   = require "bw.orm.factory"
local log       = require "bw.log"

local id_producer -- function create mid

local broadcasts = {}   -- mid: msg
local queues = {}       -- uid: {mid: msg}

local M = {}
function M.start(handler)
    id_producer = assert(handler.id_producer)
end

function M.get_broadcasts()
    return broadcasts
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
    return M.get_queue(uid)[mid]
end

-- 取消息
-- after(过滤之前的消息，通常是创角时间)
function M.fetch(uid, after)
    assert(uid)
    assert(after)
    local list = {}
    local queue = M.get_queue(uid)
    for _, v in pairs(broadcasts) do
        if v.time >= after then
            if not queue[v.mid] then
                queue[v.mid] = factory.create_obj("rmsg", v)
            end
        end
    end
    for _, v in pairs(queue) do
        if v.err < 0 and v.time >= after then
            list[#list+1] = v
        end
    end
    table.sort(list, function(a, b)
        return a.mid < b.mid
    end)

    return list
end

-- 处理结果
function M.process(uid, mid, err)
    local msg = M.get_msg(uid, mid)
    if not msg then
        log.error("[rmsg] msg not exist, uid:%s, mid:%s, err:%s", uid, mid, err)
        return
    end
    msg.err = err
end

function M.push(uid, op, args)
    assert(uid)
    assert(op)
    local queue = M.get_queue(uid)
    local mid = id_producer()
    local msg = factory.create_obj("rmsg", {
        mid = mid,
        op = op,
        time = skynet.time(),
        args = json.encode(args or {}),
        err = -1
    })
    queue[mid] = msg
    return mid
end

function M.broadcast(op, args)
    assert(op)
    local mid = id_producer()
    local msg = factory.create_obj("rmsg", {
        mid = mid,
        op = op,
        time = skynet.time(),
        args = json.encode(args or {}),
        err = -1,
    })
    broadcasts[mid] = msg
end

return M
