local skynet    = require "skynet"
local log       = require "bw.log"
local user      = require "user"
local env       = require "env"

local trace = log.trace("users")

local users = {} -- uid:user
local fd2user = setmetatable({}, {__mode = "kv"})
local half_closed = {} -- fd:bool

local M = {}
function M.open(fd, uid, ip)
    local u = users[uid]
    if u then
        local old_fd = u.fd
        u:kick()
        half_closed[old_fd] = true
        skynet.timeout(300, function()
            trace("close old_fd:%s", old_fd)
            skynet.call(env.GATE, "lua", "kick", old_fd)
            half_closed[old_fd] = nil
        end)
    else
        u = user.new(fd, uid, ip)
    end
    u.fd = fd
    users[uid] = u
    fd2user[fd] = u
    u:online()
    skynet.call(env.GATE, "lua", "forward", fd, nil, skynet.self())
    trace("forward fd:%s", fd)
end

function M.close(fd)
    local u = fd2user[fd]
    if not u or u.fd ~= fd then
        trace("close, fd:%s, u.fd:%s", fd, u and u.fd)
        return
    end
    u:close()
    trace("close, uid:%s", u.uid)
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

function M.check_timeout()
    for uid, u in pairs(users) do
        if u:check_timeout() then
            users[uid] = nil
            trace("destroy user:%s", uid)
        end
    end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = function(msg, len)
        return msg, len
    end,
	dispatch = function (fd, _, msg, len)
		skynet.ignoreret()
        if half_closed[fd] then
            return
        end
        local u = assert(fd2user[fd], fd)
        u:recv(msg, len)
	end
}

return M
