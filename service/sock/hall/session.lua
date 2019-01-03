local skynet = require "skynet"
local env = require "env"


local mt = {}
mt.__index = mt

function mt:open(fd, ip)
    self.fd     = assert(fd)
    self.ip     = assert(ip)

    skynet.call(env.GATE, "lua", "forward", fd)
end

-- 被动关闭
function mt:close()

end

-- 主动关闭
function mt:kick()
    skynet.call(env.GATE, "lua", "kick", self.fd)
end

function mt:recv(fd, msg)

end

local M = {}

function M.new(...)
    local obj = setmetatable({}, mt)
    obj:open(...)
    return obj
end

return M
