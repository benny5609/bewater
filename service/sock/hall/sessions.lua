local skynet    = require "skynet"
local log       = require "bw.log"
local agents    = require "agents"
local session   = require "session"
local env       = require "env"

local trace = log.trace("sessions")

local sessions = {} -- fd:session

local M = {}
function M.open(fd, addr)
    if not env.IS_OPEN then
        return
    end
    sessions[fd] = session.new(fd, addr)
end

function M.close(fd)
    trace("close, fd:%s", fd)
    if not sessions[fd] then
        return
    end
    sessions[fd]:close()
    sessions[fd] = nil
    agents.close(fd)
    skynet.call(env.GATE, "lua", "kick", fd)
end

function M.close_all()
    for fd, _ in pairs(sessions) do
        M.close(fd)
    end
end

function M.error(fd, msg)
    log.error("error, fd:%s, msg:%s", fd, msg)
    M.close(fd)
end

function M.warning(fd, size)
    log.error("socket warning, %sK bytes havn't send out in fd", fd, size)
end

-- 转发到agent
function M.forward_agent(fd, uid, ip)
    agents.forward(fd, uid, ip)
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
