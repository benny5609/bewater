local skynet = require "skynet"
local ctx = require "bw.context"

local mt = {}
mt.__index = mt

function mt:open(gate, fd, ip, port, uid)
    self.gate   = assert(gate)
    self.fd     = assert(fd)
    self.ip     = assert(ip)
    self.port   = assert(port)
    self.uid    = assert(uid)
    
    skynet.call(self.gate, "lua", "forward", fd)
end

-- 被动关闭
function M:close()

end

-- 主动关闭
function M:kick()
    skynet.call(self.gate, "lua", "kick", self.fd)
end

local M = {}

function M.new(...)
    local obj = setmetatable({}, mt)
    obj:open(...)
    return obj
end

return M
