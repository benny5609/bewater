-- 钉钉警报系统
local Skynet = require "skynet"
local Http   = require "web.http_helper"
local Util   = require "util"
local Conf   = require "conf"
local Log    = require "log"
local Json   = require "cjson"

local print  = Log.print("alert")
local trace  = Log.trace("alert")
require "bash"

local host = "https://oapi.dingtalk.com"
local function get_token()
    local ret, resp = Http.get(host.."/gettoken", {corpid = Conf.alert.corpid, corpsecret = Conf.alert.corpsecret})
    if ret then
        local data = Json.decode(resp)
        return data.access_token
    else
        Skynet.error("cannot get token")
    end 
end


local count = 0 -- 一分钟内累计报错次数
local last = 0  -- 上次报错时间
local function send_traceback()
    local info = require "Util.clusterinfo"
    local path = string.format("%s/log/%s.log", info.workspace, Skynet.getenv("clustername") or "error")
    local str = string.format("服务器TRACEBACK\n项目:%s\n节点:%s\n公网ip:%s\n内网ip:%s\n进程:%s\n路径:%s\n累计报错:%d次",
        Conf.desc or Conf.proj, info.clustername, info.pnet_addr, info.inet_addr, info.pid, path, count)

    count = 0
    last = os.time()

    local token = get_token()
    local sh = string.format('curl -H "Content-Type:application/json" -X POST -d \'%s\' %s/chat/send?access_token=%s', Json.encode {
        sender = Conf.alert.sender,
        chatid = Conf.alert.chatid,
        msgtype = "text",
        text = { 
            content = str,
        } 
    }, host, token)
    --print(sh)
    bash(sh)
    
end

local CMD = {}
function CMD.traceback(err)
    count = count + 1
    if os.time() - last < 60 then
        return
    end
    send_traceback() 
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
    local sh = string.format('curl -H "Content-Type:application/json" -X POST -d \'%s\' %s/chat/send?access_token=%s', Json.encode {
        sender = Conf.alert.sender,
        chatid = Conf.alert.chatid,
        msgtype = "text",
        text = { 
            content = str,
        } 
    }, host, token)
    --print(sh)
    bash(sh)

end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)

    Skynet.fork(function()
        while true do
            if count > 0 then
                send_traceback()
            end
            Skynet.sleep(6000)
        end
    end)
end)
