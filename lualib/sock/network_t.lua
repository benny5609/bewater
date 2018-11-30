local Skynet    = require "skynet"
local Class     = require "class"
local Socket    = require "skynet.socket"
local Packet    = require "sock.packet"
local Util      = require "util"
local Def       = require "def"
local Opcode    = require "def.opcode"
local Errcode   = require "def.errcode"
local Protobuf  = require "protobuf"
local Md5       = require "md5"

local M = Class("network_t")
function M:ctor(player)
    self.player = assert(player, "network need player")
end

function M:init(watchdog, gate, agent, fd, ip)
    self._watchdog = assert(watchdog)
    self._gate = assert(gate)
    self._agent = assert(agent)
    self._fd = assert(fd)
    self._ip = assert(ip)
    self._csn = 0
    self._ssn = 0
    self._crypt_key = 0
    self._crypt_type = 0
    self._token = nil
    self._ping_time = Skynet.time()
end

function M:check_timeout()
    if Skynet.time() - self._ping_time > Def.PING_TIMEOUT and self._fd then
        self:close()
    end
end

function M:create_token()
    self._token = Md5.crypt(string.format("%d%d", self.player.uid, os.time()), "Stupid")
    return self._token
end

function M:call_watchdog(...)
    return Skynet.call(self._watchdog, "lua", ...)
end

function M:call_gate(...)
    return Skynet.call(self._gate, "lua", ...)
end

function M:call_agent(...)
    return Skynet.call(self._agent, "lua", ...)
end

function M:send(op, tbl, csn)
    if Opcode.has_session(op) then
        self._ssn = self._ssn + 1
    end
    local data, len
    Protobuf.encode(Opcode.toname(op), tbl or {}, function(buffer, bufferlen)
        data, len = Packet.pack(op, csn or 0, self._ssn,
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)
	Socket.write(self._fd, data, len)
end

function M:recv(op, csn, ssn, crypt_type, crypt_key, buff, sz)
    self._ping_time = Skynet.time()

    local opname = Opcode.toname(op)
    local modulename = Opcode.tomodule(op)
    local simplename = Opcode.tosimplename(op)
    if Opcode.has_session(op) then
        Skynet.error(string.format("recv package, 0x%x %s, csn:%d, ssn:%d, crypt_type:%s, crypt_key:%s, sz:%d",
            op, opname, csn, ssn, crypt_type, crypt_key, sz))
    end

    local data = Protobuf.decode(opname, buff, sz)
    assert(type(data) == "table", data)
    --Util.printdump(data)

    local ret = 0 -- 返回整数为错误码，table为返回客户端数据
    local mod = assert(self.player[modulename], modulename)
    local f = assert(mod[simplename], simplename)
    if not Util.try(function()
        ret = f(mod, data) or 0
    end) then
        ret = Errcode.TRACEBACK
    end
    if type(ret) == "table" then
        ret.err = ret.err or 0
    else
        ret = {err = ret}
    end
    self:send(op+1, ret, csn)
end

function M:close()
    Skynet.call(self._gate, "lua", "kick", self._fd)
end

-- fd, csn, ssn, passport
function M:reconnect(fd, csn, ssn, passport, user_info)
    Skynet.error("&&&&&& reconnect")
    self:send(Opcode.user.s2c_kickout)
    self:close()
    self._fd = fd
    --self.player:online()
    self.player.is_cache = false
    self.player.user:init_by_data(user_info)
    self:call_watchdog("player_online", self:get_agent(), self.player.uid, fd)
    self.player:sync_all()
    return true
end

function M:get_fd()
    return self._fd
end

function M:get_csn()
    return self._csn
end

function M:get_ssn()
    return self._ssn
end

function M:get_agent()
    return self._agent
end

function M:get_ip()
    return self._ip
end

return M
