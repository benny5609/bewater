local skynet    = require "skynet"
local log       = require "bw.log"
local agents    = require "agents"
local user      = require "user"
local env       = require "env"

local trace = log.trace("users")

local users = {} -- fd:user

local M = {}
function M.open(fd, addr)
    users[fd] = user.new(fd, addr)
end

function M.close(fd)
    trace("close, fd:%s", fd)
    users[fd] = nil
    skynet.call(env.GATE, "lua", "kick", fd)
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
		skynet.ignoreret()
        local s = assert(users[fd], fd)
        s:recv(msg, len)
	end
}

return M
