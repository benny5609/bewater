-- 集群节点相关信息
-- 访问方式 clusterinfo.xxx or clusterinfo.get_xxx()
--
local Skynet = require "skynet"
local Http   = require "web.http_helper"
local Conf   = require "conf"
local Util   = require "util"
require "bash"

local M = {}
local _cache = {}
setmetatable(M, {
    __index = function (t, k)
        local v = rawget(t, k)
        if v then
            return v
        end
        local f = rawget(t, '_'..k)
        if f then
            v = _cache[k] or f()
            _cache[k] = v
            return v
        end
        f = rawget(t, 'get_'..k)
        assert(f, "no clusterinfo "..k)
        return f()
    end
})

-- 公网ip
function M._pnet_addr()
    if Conf.remote_host then
        if Conf.remote_port then
            return Conf.remote_host .. ":" .. Conf.remote_port
        else
            return Conf.remote_host
        end
    end
    if Conf.host then
        if Conf.port then
            return Conf.host .. ":" .. Conf.port
        else
            return Conf.host
        end
    end
    local _, resp = Http.get('http://members.3322.org/dyndns/getip')
    local addr = string.gsub(resp, "\n", "")
    return addr
end

-- 内网ip
function M.get_inet_addr()
    local ret = bash "ifconfig eth0"
    return string.match(ret, "inet addr:([^%s]+)") or string.match(ret, "inet ([^%s]+)")
end

function M.get_run_time()
    return Skynet.time()
end

-- 进程pid
function M._pid()
    local filename = Skynet.getenv "daemon"
    if not filename then
        return
    end
    local pid = bash("cat %s", filename)
    return string.gsub(pid, "\n", "")
end

function M.get_profile()
    local pid = M.pid
    if not pid then return end
    local ret = bash(string.format('ps -p %d u', pid))
    local list = Util.split(string.match(ret, '\n(.+)'), ' ')
    return {
        cpu = tonumber(list[3]),
        mem = tonumber(list[6]),
    }
end

function M._proj()
    return Conf.proj
end

function M._clustername()
    return Skynet.getenv "clustername"
end

-- 绝对路径
function M._workspace()
    local path = bash("cd %s && pwd", Conf.workspace)
    return string.gsub(path, "\n", "")
end


return M
