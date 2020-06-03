--  reliable message
--  可靠消息
local skynet    = require "skynet"
local json      = require "cjson.safe"
local factory   = require "bw.orm.factory"
local log       = require "bw.log"

local id_producer     -- function create mid
local notify          -- function notify
local load_queue      -- function load_queue
local save_queue      -- function save_queue
local load_broadcasts -- function load_broadcasts
local save_broadcasts -- function save_broadcasts

local broadcasts = {}   -- mid: msg
local queues = {}       -- uid: {mid: msg}

local M = {}
function M.start(handler)
    id_producer     = assert(handler.id_producer)
    load_broadcasts = assert(handler.load_broadcasts)
    save_broadcasts = assert(handler.save_broadcasts)
    load_queue      = assert(handler.load_queue)
    save_queue      = assert(handler.save_queue)
    notify          = handler.notify

    broadcasts = load_broadcasts()
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
        queue = load_queue(uid)
        queues[uid] = queue
    end
    return queue
end

function M.get_msg(uid, mid)
    return M.get_queue(uid)[mid]
end

-- 取消息
-- after(过滤之前的消息，通常是上一次取消息的时间)
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
    local queue = M.get_queue(uid)
    local msg = queue[mid]
    if not msg then
        log.error("[rmsg] msg not exist, uid:%s, mid:%s, err:%s", uid, mid, err)
        return
    end
    msg.err = err
    save_queue(uid, queue)
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
    save_queue(uid, queue)
    if notify then
        notify(uid)
    end
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
    save_broadcasts(broadcasts)
end

return M
