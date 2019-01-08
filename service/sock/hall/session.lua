local skynet    = require "skynet"
local socket    = require "skynet.socket"
local bewater   = require "bw.bewater"
local packet    = require "bw.sock.packet"
local protobuf  = require "bw.protobuf"
local util      = require "bw.util"
local log       = require "bw.log"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local env       = require "env"

local trace = log.trace("session")

local mt = {}
mt.__index = mt

function mt:open(fd, ip)
    self.fd = assert(fd)
    self.ip = assert(ip)

    local visitor = require(env.VISITOR)
    self.visitor = visitor.new(self)

    skynet.call(env.GATE, "lua", "forward", fd)
end

-- 被动关闭
function mt:close()
    trace("close", self.fd)
end

-- 主动关闭
function mt:kick()
    self:close()
    skynet.call(env.GATE, "lua", "kick", self.fd)
end

function mt:send(op, data)
    local msg, len
    protobuf.encode(opcode.toname(op), data or {}, function(buffer, bufferlen)
        msg, len = packet.pack(op, self.csn or 0, self.ssn or 0,
            self.crypt_type or 0, self.crypt_key or 0, buffer, bufferlen)
    end)
	socket.write(self.fd, msg, len)
end

function mt:recv(msg, len)
    local op, csn, ssn, crypt_type, crypt_key, buff, sz = packet.unpack(msg, len)

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        skynet.error(string.format("recv package, 0x%x %s, csn:%d, ssn:%d, crypt_type:%s, crypt_key:%s, sz:%d",
            op, opname, csn, ssn, crypt_type, crypt_key, sz))
    end

    local data = protobuf.decode(opname, buff, sz)
    assert(type(data) == "table", data)
    trace("recv, op:%s, data:%s", opcode.toname(op), util.dump(data))
    --util.printdump(data)

    local ret = 0 -- 返回整数为错误码，table为返回客户端数据
    local mod = assert(self.visitor[modulename], modulename)
    local f = assert(mod[simplename], simplename)
    if not bewater.try(function()
        ret = f(mod, data) or 0
    end) then
        ret = errcode.TRACEBACK
    end
    if type(ret) == "table" then
        ret.err = ret.err or 0
    else
        ret = {err = ret}
    end
    self:send(op+1, ret)
end

local M = {}

function M.new(...)
    local obj = setmetatable({}, mt)
    obj:open(...)
    return obj
end

return M
