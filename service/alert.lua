-- 钉钉警报系统
local skynet = require "skynet"
local http   = require "web.http_helper"
local bewater= require "bewater"
local conf   = require "conf"
local log    = require "log"
local json   = require "cjson.safe"

local trace  = log.trace("alert")
require "bash"

local host = "https://oapi.dingtalk.com"
local function get_token()
    local ret, resp = http.get(host.."/gettoken", {corpid = conf.alert.corpid, corpsecret = conf.alert.corpsecret})
    if ret then
        local data = json.decode(resp)
        return data.access_token
    else
        skynet.error("cannot get token")
    end
end


local count = 0 -- 一分钟内累计报错次数
local last = 0  -- 上次报错时间
local function send_traceback()
    if skynet.time() - last < 60 then
        return
    end
    local info = require "util.clusterinfo"
    local path = string.format("%s/log/error.log", info.workspace)
    local str = string.format("服务器出错了\n项目:%s\n节点:%s\n公网ip:%s\n内网ip:%s\n进程:%s\n日志:%s\n累计报错:%d次",
        conf.desc or conf.proj, info.clustername, info.pnet_addr, info.inet_addr, info.pid, path, count)

    count = 0
    last = skynet.time()

    local token = get_token()
    local sh = string.format('curl -H "Content-Type:application/json" -X POST -d \'%s\' %s/chat/send?access_token=%s',
    json.encode {
        sender = conf.alert.sender,
        chatid = conf.alert.chatid,
        msgtype = "text",
        text = {
            content = str,
        }
    }, host, token)
    bash(sh)

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
    -- 暂时先用curl发https post
    local token = get_token()
    local sh = string.format('curl -H "Content-Type:application/json" -X POST -d \'%s\' %s/chat/send?access_token=%s',
    json.encode {
        sender = conf.alert.sender,
        chatid = conf.alert.chatid,
        msgtype = "text",
        text = {
            content = str,
        }
    }, host, token)
    bash(sh)

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
