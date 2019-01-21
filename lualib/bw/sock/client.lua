local skynet    = require "skynet"
local socket    = require "skynet.socket"
local coroutine = require "skynet.coroutine"
local packet    = require "bw.sock.packet"
local protobuf  = require "bw.protobuf"
local class     = require "bw.class"
local bewater   = require "bw.bewater"
local log       = require "bw.log"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local packetc   = require "packet.core"

local trace = log.trace("client")

local M = {}
function M:ctor(proj)
    self._proj = proj
    self._host = nil
    self._port = nil
    self._fd = nil
    self._csn = 0 -- client session
    self._ssn = 0 -- server session
    self._crypt_type = 0
    self._crypt_key = 0

    self._call_requests = {} -- op -> co
    self._waiting = {} -- co -> time
    self._cache = ""
end

function M:start(host, port)
    self._host = assert(host)
    self._port = assert(port)
    self._fd = socket.open(self._host, self._port)
    assert(self._fd)

    skynet.fork(function()
        while true do
            local buff = socket.read(self._fd)
            if not buff then
                self:offline()
                return
            end
            self._cache = self._cache .. buff
            while true do
                local cache = self._cache
                if self._cache == "" then
                    break
                end
                local sz = string.unpack(">H", cache)
                if #cache < sz then
                    break
                end
                buff = string.sub(cache, 3, 2 + sz)
                self._cache = string.sub(cache, 3 + sz, -1)
                self:_recv(buff)
            end

        end
    end)

    -- ping
    skynet.fork(function()
        while true do
            self:ping()
            skynet.sleep(100*30)
        end
    end)

    -- tick
    self.tick = 0
    skynet.fork(function()
        while true do
            self.tick = self.tick + 1
            skynet.sleep(1)
            for co, time in pairs(self._waiting) do
                if time <= 0 then
                    self:_suspended(co)
                else
                    self._waiting[co] = time - 1
                end
            end
        end
    end)
end

function M:create(func)
    local co = coroutine.create(function()
        bewater.try(func)
    end)
    self:_suspended(co)
end

function M:call(op, data, expect_err)
    self:send(op, data)
    local ret = coroutine.yield(op)
    local code = ret and ret.err
    if code ~= (expect_err or 0) then
        error(string.format("call %s error:0x%x, desc:%s",
            opcode.toname(op), code, errcode.describe(code)))
    end
    return ret
end

function M:wait(time)
    return coroutine.yield(nil, time)
end

function M:close()
    socket.close(self._fd)
end

function M:send(op, tbl)
    self._csn = self._csn + 1

    local data, len
    protobuf.encode(opcode.toname(op), tbl or {}, function(buffer, bufferlen)
        data, len = packet.pack(op, self._csn, self._ssn,
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)

    trace("send %s, csn:%d, sz:%s", opcode.toname(op), self._csn, len)
    socket.write(self._fd, data, len)
end

function M:ping()
    -- overwrite
end

function M:offline()
    -- overwrite
end


function M:_recv(sock_buff)
    local data      = packetc.new(sock_buff)
    --local total     = data:read_ushort()
    local op    = data:read_ushort()
    local csn   = data:read_ushort()
    local ssn   = data:read_ushort()
    data:read_ubyte() -- crypt_type
    data:read_ubyte() -- crypt_key
    local sz    = #sock_buff - 8
    local buff  = data:read_bytes(sz)
    --local op, csn, ssn, crypt_type, crypt_key, buff, sz = packet.unpack(sock_buff)
    self._ssn = ssn

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    local funcname = modulename .. "_" .. simplename

    data = protobuf.decode(opname, buff, sz)
    if self[funcname] then
        self[funcname](self, data)
    end

    local co = self._call_requests[op - 1]

    assert(data, opname)
    trace("recv %s, csn:%d ssn:%d co:%s", opname, csn, ssn, co)
    assert(self._csn == csn or csn == 0, string.format("self._csn:%d, csn:%d", self._csn, csn))

    self._call_requests[op - 1] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, op, data)
    end
end

function M:_suspended(co, _op, ...)
    assert(_op == nil or _op >= 0)
    local _, op, wait = coroutine.resume(co, ...)
    if coroutine.status(co) == "suspended" then
        if op then
            self._call_requests[op] = co
        end
        if wait then
            self._waiting[co] = wait
        end
    end
end

return class(M)
