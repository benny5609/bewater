local skynet = require "skynet"
local class = require "class"

local M = class("timer_t")
function M:ctor()
    self._top = nil
    self._cancel = nil
end

function M:destroy()
    if self._cancel then
        self._cancel()
    end
    self._top = nil
    self._cancel = nil
end

function M:cancelable_timeout(ti, func)
    local function cb()
        if func then
            func()
        end
    end
    local function cancel()
        func = nil
    end
    skynet.timeout(ti * 100, cb)
    return cancel
end

function M:start()
    assert(self._top)
    self._cancel = cancelable_timeout(self._top.ti - skynet.time(), function()
        self._top.cb()
        self:next()
    end)
end

function M:cancel()
    self._cancel()
end

function M:next()
    self._top = self._top.next
    if self._top then
        self:start()
    end
end

function M:timeout(expire, cb)
    assert(type(expire) == "number")
    assert(type(cb) == "function")
    
    local node = {
        ti = skynet.time() + expire,
        cb = cb,
    }

    if not self._top then
        self._top = node 
        self:start()
    else
        if node.ti < self._top.ti then
            node.next = self._top
            self._top = node
            self:cancel()
            self:start()
        else
            local cur = self._top
            local prev
            while cur do 
                if cur.ti <= node.ti then
                    if prev then
                        prev.next = node
                    end
                    node.next = cur
                    return
                end
                prev = cur
                cur = cur.next
            end
            cur.next = node
        end
    end
end

return M

