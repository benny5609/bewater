local skynet    = require "skynet"
local log       = require "bw.log"
local user      = require "user"
local env       = require "env"

local trace = log.trace("users")

local users = {} -- fd:user
local fd2user = setmetatable({}, {__mode = "kv"})

local M = {}
function M.open(fd, uid, ip)
    local user = user.new(fd, uid, ip)
    users[uid] = user
    fd2user[fd] = user
    skynet.call(env.GATE, "lua", "forward", fd, nil, skynet.self())
    trace("forward fd:%s", fd)
end

function M.close(fd)
    trace("close, fd:%s", fd)
    users[fd]:close()
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

function M.get_user(uid)
    return users[uid]
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = function(msg, len)
        return msg, len
    end,
	dispatch = function (fd, _, msg, len)
		skynet.ignoreret()
        local u = assert(fd2user[fd], fd)
        u:recv(msg, len)
	end
}

return M
