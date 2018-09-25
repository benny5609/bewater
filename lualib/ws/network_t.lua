local skynet    = require "skynet"
local socket    = require "skynet.socket"
local ws_server = require "ws.server"
local class     = require "class"
local util      = require "util"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local protobuf  = require "protobuf"
local json      = require "cjson"

local M = class("network_t")
function M:ctor(player)
    self.player = assert(player, "network need player")
end

function M:init(watchdog, agent, fd, ip)
    self._watchdog = assert(watchdog)
    self._agent = assert(agent)
    self._fd = assert(fd)
    self._ip = assert(ip)
    self._csn = 0
    self._ssn = 0
    self._ping_time = os.time()

    local handler = {}
    function handler.open()
        self._ping_time = os.time()
    end
    function handler.text(t)
        self._ping_time = os.time()
        self.send_type = "text"
        self:_recv_text(t)
    end
    function handler.binary(sock_buff)
        self._ping_time = os.time()
        self.send_type = "binary"
        self:_recv_binary(sock_buff)
    end
    function handler.close()
        if self.player.offline then
            self.player:offline()
        end
    end
    self._ws = ws_server.new(fd, handler)
    skynet.fork(function()
        while true do
            skynet.sleep(100)
            if os.time() - self._ping_time > 300 then
                if self._ws then
                    self._ws:send_close()
                    self._ws.sock:close()
                end
                return
                --self.player:offline()
            end
        end
    end)
end

function M:call_watchdog(...)
    return skynet.call(self._watchdog, "lua", ...)
end

function M:call_agent(...)
    return skynet.call(self._agent, "lua", ...)
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

function M:send(...)
    if self.send_type == "binary" then
        self:_send_binary(...)
    elseif self.send_type == "text" then
        self:_send_text(...)
    else
        error(string.format("send error send_type:%s", self.send_type))
    end
end

function M:_send_text(op, msg) -- 兼容text
    self._ws:send_text(json.encode({
        op  = op,
        msg = msg,
    }))
end

function M:_send_binary(op, tbl)
    local data = protobuf.encode(opcode.toname(op), tbl or {})
    --print("send", #data)
    -- self._ws:send_binary(string.pack(">Hs2", op, data))
    if opcode.has_session(op) then
        self._ssn = self._ssn + 1
    end
    self._ws:send_binary(string.pack(">HHH", op, self._csn, self._ssn)..data)
end

function M:_recv_text(t)
    local data = json.decode(t)
    local recv_op = data.op
    local modname, recv_op = string.match(data.op, "([^.]+).(.+)")
    local mod = assert(self.player[modname], modname)
    local f =assert(mod[recv_op], recv_op)
    local resp_op = modname..".s2c_"..string.match(recv_op, "c2s_(.+)")
    local msg = f(mod, data.msg) or {}
    self._ws:send_text(json.encode({
        op = resp_op,
        msg = msg,
    }))
end

function M:_recv_binary(sock_buff)
    --local op, buff = string.unpack(">Hs2", sock_buff)
    local op, csn, ssn = string.unpack(">HHH", sock_buff)
    local buff = string.sub(sock_buff, 7, #sock_buff) or ""
    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    self._csn = csn
    self._ssn = ssn

    skynet.error(string.format("recv_binary %s %s %s", opname, op, #buff))
    local data = protobuf.decode(opname, buff)
    --util.printdump(data)

    local player = self.player
    if not util.try(function()
        assert(player, "player nil")
        assert(player[modulename], string.format("module nil [%s.%s]", modulename, simplename))
        assert(player[modulename][simplename], string.format("handle nil [%s.%s]", modulename, simplename))
        ret = player[modulename][simplename](player[modulename], data) or 0
    end) then
        ret = errcode.TRACEBACK
    end 

    assert(ret, string.format("no respone, opname %s", opname))
    if type(ret) == "table" then
        ret.err = ret.err or 0
    else
        ret = {err = ret} 
    end                                                                                                                                                                                                                              
    self:send(op+1, ret)
end

function M:close()
    self._ws.sock:close()
end

function M:reconnect(csn, ssn)
    assert(csn and ssn)
    --self._ws:send_close()
    self._ws.sock:close()
    if self._csn ~= csn or self._ssn ~= ssn then
        return errcode.RELOGIN, self.player:base_data()
    else
        return errcode.RECONNECTED, self.player:base_data()
    end
end

function M:get_agent()
    return self._agent
end

function M:get_ip()
    return self._ip
end


return M
