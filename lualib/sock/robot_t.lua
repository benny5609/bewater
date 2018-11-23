local Skynet    = require "skynet"
local Socket    = require "skynet.socket"
local Http      = require "web.http_helper"
local Packet    = require "sock.packet"
local Packetc   = require "packet.core"
local Protobuf  = require "protobuf"
local Opcode    = require "def.opcode"
local Errcode   = require "def.errcode"
local Util      = require "util"
local Json      = require "cjson"
local Class     = require "class"

local coroutine = require "skynet.coroutine"

local M = Class("robot_t")
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

function M:login()
    --local ret, resp = Http.get("http://www.kaizhan8.com:8888/login/req_login", {
    local _, resp = Http.get("http://huangjx.top/login/req_login", {
        proj = self._proj
    })
    if resp == "error" then
        return
    end
    --print(ret, resp)
    local data = Json.decode(resp)
    self._host = data.host
    self._port = data.port
end

function M:start(host, port)
    self._host = assert(host)
    self._port = assert(port)
    self._fd = Socket.open(self._host, self._port)
    assert(self._fd)

    Skynet.fork(function()
        while true do
            local buff = Socket.read(self._fd)
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
    Skynet.fork(function()
        while true do
            self:ping()
            Skynet.sleep(100*30)
        end
    end)

    -- tick
    self.tick = 0
    Skynet.fork(function()
        while true do
            self.tick = self.tick + 1
            Skynet.sleep(1)
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

function M:test(func)
    local co = coroutine.create(function()
        Util.try(func)
    end)
    self:_suspended(co)
end

function M:call(op, data)
    self:send(op, data)
    local ret = coroutine.yield(op)
    local code = ret and ret.err
    if code ~= 0 then
        Skynet.error(string.format("call %s error:0x%x, desc:%s",
            Opcode.toname(op), code, Errcode.describe(code)))
    end
    return ret
end

function M:wait(time)
    return coroutine.yield(nil, time)
end

function M:send(op, tbl)
    self._csn = self._csn + 1

    local data, len
    Protobuf.encode(Opcode.toname(op), tbl or {}, function(buffer, bufferlen)
        data, len = Packet.pack(op, self._csn, self._ssn,
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)

    print(string.format("send %s, csn:%d, sz:%s", Opcode.toname(op), self._csn, len))
    Socket.write(self._fd, data, len)
end

function M:ping()
    -- overwrite
end

function M:offline()
    -- overwrite
end


function M:_recv(sock_buff)
    local data      = Packetc.new(sock_buff)
    --local total     = data:read_ushort()
    local op    = data:read_ushort()
    local csn   = data:read_ushort()
    local ssn   = data:read_ushort()
    data:read_ubyte() -- crypt_type
    data:read_ubyte() -- crypt_key
    local sz    = #sock_buff - 8
    local buff  = data:read_bytes(sz)
    --local op, csn, ssn, crypt_type, crypt_key, buff, sz = Packet.unpack(sock_buff)
    self._ssn = ssn

    local opname = Opcode.toname(op)
    local modulename = Opcode.tomodule(op)
    local simplename = Opcode.tosimplename(op)
    local funcname = modulename .. "_" .. simplename

    print(string.format("recv %s, csn:%d ssn:%d", opname, csn, ssn))

    data = Protobuf.decode(opname, buff, sz)
    if self[funcname] then
        self[funcname](self, data)
    end

    local co = self._call_requests[op - 1]
    self._call_requests[op - 1] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, op, data)
    end
end

function M:_suspended(co, op, ...)
    assert(op == nil or op >= 0)
    local _, _, wait = coroutine.resume(co, ...)
    if coroutine.status(co) == "suspended" then
        if op then
            self._call_requests[op] = co
        end
        if wait then
            self._waiting[co] = wait
        end
    end
end

return M
