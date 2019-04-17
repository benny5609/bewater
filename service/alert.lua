-- 企业微信警报系统
local skynet    = require "skynet"
local http      = require "bw.web.http_helper"
local bewater   = require "bw.bewater"
local log       = require "bw.log"
local lock      = require "bw.lock"
local util      = require "bw.util"
local bash      = require "bw.util.bash"
local json      = require "cjson.safe"
local conf      = require "conf"

local trace  = log.trace("alert")
local send_lock = lock.new()
local host = "https://qyapi.weixin.qq.com"
local access_token = ''
local expires = 0

local function request_token()
    local ret, resp = http.get(host.."/cgi-bin/gettoken", {
        corpid = conf.alert.corpid,
        corpsecret = conf.alert.corpsecret
    })
    if ret then
        local data = json.decode(resp)
        if data.errcode ~= 0 then
            skynet.error("alert request_token error", util.dump(data))
            return
        end
        access_token = data.access_token
        expires = skynet.time() + data.expires_in
        skynet.error("alert request_token:", access_token)
        return access_token
    else
        skynet.error("cannot get token")
    end
end

local function get_token()
    if skynet.time() < expires then
        return access_token
    end
    return request_token()
end

local function send(str)
    local token = get_token()
    local ret, resp_str = http.post(string.format("%s/cgi-bin/message/send?access_token=%s", host, token), json.encode{
        touser = "@all",
        agentid = conf.alert.agentid,
        msgtype = "text",
        text = {content = str},
    })
    local resp = json.decode(resp_str)
    if resp and resp.errcode == 40014 then
        if request_token() then
            send(str)
        end
    else
        skynet.error("alert send error", ret, resp_str)
    end
end

local count = 0 -- 一分钟内累计报错次数
local last = 0  -- 上次报错时间
local function send_traceback()
    send_lock:lock()
    if skynet.time() - last < 60 or count == 0 then
        return
    end
    local info = require "bw.util.clusterinfo"
    local path = string.format("%s/log/error.log", info.workspace)
    local str = string.format("服务器出错了\n项目:%s\n节点:%s\n公网ip:%s\n内网ip:%s\n进程:%s\n日志:%s\n累计报错:%d次",
        conf.desc or conf.proj, info.clustername, info.pnet_addr, info.inet_addr, info.pid, path, count)

    count = 0
    last = skynet.time()
    send(str)
    send_lock:unlock()
end

local CMD = {}
function CMD.traceback(err)
    count = count + 1
    send_traceback(err)
end

function CMD.node_dead(proj, clustername, pnet_addr, inet_addr, pid, cpu, mem)
    local str = string.format("救命啊，有节点挂掉了!\n项目:%s\n节点:%s\n公网ip:%s\n内网ip:%s\n进程: pid:%s CPU:%s MEM:%.1fM",
        proj, clustername, pnet_addr, inet_addr, pid, cpu, mem/1024)
    trace(str)
    CMD.test(str)
end

function CMD.test(str)
    send(str)
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        bewater.ret(f(...))
    end)

    skynet.fork(function()
        while true do
            if count > 0 then
                send_traceback()
            end
            skynet.sleep(6000)
        end
    end)
end)
