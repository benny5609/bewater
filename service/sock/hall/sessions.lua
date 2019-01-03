--local skynet = require "skynet"
local log = require "bw.log"
local session = require "session"

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

function M.data(fd, msg)
    local s = assert(sessions[fd], fd)
    s:recv(fd, msg)
end

return M
