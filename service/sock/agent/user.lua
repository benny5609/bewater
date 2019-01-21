local skynet    = require "skynet"
local socket    = require "skynet.socket"
local bewater   = require "bw.bewater"
local packet    = require "bw.sock.packet"
local protobuf  = require "bw.protobuf"
local class     = require "bw.class"
local util      = require "bw.util"
local log       = require "bw.log"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local env       = require "env"

local trace = log.trace("user")

local mt = {}
mt.__index = mt

function mt:ctor(fd, uid, ip)
    self.fd  = assert(fd)
    self.uid = assert(uid)
    self.ip  = assert(ip)
    self.csn = 0
    self.ssn = 0
    self.crypt_key = 0
    self.crypt_type = 0

    local role = require(env.ROLE)
    self.role = role.new(uid)

    trace("new user, fd:%s, uid:%s", fd, uid)
end

-- 被动关闭
function mt:close()
    trace("onclose")
    if self.role.offline then
        self.role:offline()
    end
end

-- 主动关闭
function mt:kick()
    if self.role.kickout then
        self.role:kickout()
    end
end

function mt:online()
    trace("online")
    if self.role.online then
        self.role:online()
    end
end

function mt:send(op, data, csn)
    trace("send:%s, fd:%s, csn:%s", opcode.toname(op), self.fd, csn)
    local msg, len
    protobuf.encode(opcode.toname(op), data or {}, function(buffer, bufferlen)
        msg, len = packet.pack(op, csn or 0, self.ssn,
            self.crypt_type, self.crypt_key, buffer, bufferlen)
    end)
	socket.write(self.fd, msg, len)
end

function mt:recv(msg, len)
    local op, csn, ssn, crypt_type, crypt_key, buff, sz = packet.unpack(msg, len)
    self.csn = csn
    self.ssn = ssn
    self.crypt_type = crypt_type
    self.crypt_key = crypt_key

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        self.ssn = self.ssn + 1
        skynet.error(string.format("recv package, 0x%x %s, csn:%d, ssn:%d, crypt_type:%s, crypt_key:%s, sz:%d",
            op, opname, csn, ssn, crypt_type, crypt_key, sz))
    end

    local data = protobuf.decode(opname, buff, sz)
    assert(type(data) == "table", data)
    trace("recv, op:%s, csn:%s, fd:%s, data:%s", opcode.toname(op), csn, self.fd, util.dump(data))
    --util.printdump(data)

    local ret = 0 -- 返回整数为错误码，table为返回客户端数据
    local mod = assert(self.role[modulename], opcode.toname(op))
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
    self:send(op+1, ret, csn)
end

function mt:check_timeout()
    local flag = false
    if self.role.is_timeout then
        flag = self.role:is_timeout()
    end
    if flag then
        self.role:destroy()
    end
    return flag
end

return class(mt)
