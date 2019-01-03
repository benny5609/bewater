local skynet    = require "skynet"
local session   = require "session"
local log       = require "bw.log"

local trace = log.trace("sessions")

local sessions = {} -- fd:session

local M = {}
function M.open(fd, addr)
    sessions[fd] = session.new(fd, addr)
end

function M.close(fd)
    trace("close, fd:%s", fd)
    sessions[fd] = nil
end

function M.error(fd, msg)
    log.error("error, fd:%s, msg:%s", fd, msg)
    M.close(fd)
end

function M.warning(fd, size)
    log.error("socket warning, %sK bytes havn't send out in fd", fd, size)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = function(msg, len)
        return msg, len
    end,
	dispatch = function (fd, _, msg, len)
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
        local s = assert(sessions[fd], fd)  
        s:recv(msg, len)
	end
}

return M
