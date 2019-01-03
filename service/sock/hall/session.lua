local skynet    = require "skynet"
local network   = require "bw.sock.network"
local util      = require "bw.util"
local log       = require "bw.log"
local opcode    = require "def.opcode"
local env       = require "env"

local trace = log.trace("session")

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

function mt:recv(msg, len)
    local op, data = network.recv(msg, len)
    trace("recv, op:%s, data:%s", opcode.toname(op), util.dump(data))
end

local M = {}

function M.new(...)
    local obj = setmetatable({}, mt)
    obj:open(...)
    return obj
end

return M
