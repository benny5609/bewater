local socket    = require "skynet.socket"
local packet    = require "bw.sock.packet"
local protobuf  = require "bw.protobuf"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"

local M = {}
function M.send(fd, op, data, csn, ssn, crypt_key, crypt_key)
    local msg, len
    protobuf.encode(opcode.toname(op), data or {}, function(buffer, bufferlen)
        msg, len = packet.pack(op, csn or 0, ssn or 0,
            crypt_type, crypt_key, buffer, bufferlen)
    end)
	socket.write(fd, msg, len)
end

function M.recv(msg, len)
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
    return op, data, csn, ssn, crypt_type, crypt_key
end

return M
