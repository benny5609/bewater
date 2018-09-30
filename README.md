# 基于skynet的通用服务器
  方便多个项目一起维护，支持sock,web,websock
# 项目结构
```
common(通用模块,本仓库) https://github.com/zhandouxiaojiji/common.git
    luaclib(编译好的c库)
    lualib-src(c库源码)
    lualib(lua库)
    service(通用服务)
skynet(fork skynet项目，不作任何改动)
proj
    xxgame(你的项目)
        lualib(项目lua库)
        service(项目用到的服务)
        script(项目的逻辑脚本)
    monitor(监视节点) https://github.com/zhandouxiaojiji/monitor.git
    share(数据共享节点) https://github.com/zhandouxiaojiji/share.git
    
生成项目的脚本:common/tools/workspace.sh
```
# 配置
```
mkdir workspace
cd workspace
git clone https://github.com/zhandouxiaojiji/common.git
git clone https://github.com/zhandouxiaojiji/skynet.git
mkdir proj #项目目录，参考monitor和share
cd skynet && make linux
cd ../proj
git clone https://github.com/zhandouxiaojiji/share.git
git clone https://github.com/zhandouxiaojiji/monitor.git
cd monitor/shell
sh etc.sh monitor monitor monitor #生成启动配置, etc.sh [配置名] [启动脚本] [集群名] [是否以进程的方式启动]
./run.sh monitor #启动进程, run.sh [配置名]
```
# 脚本与库检索优先级
```
项目>common>skynet
这三个目录下都有luaclib,lualib-src,lualib,service这几个目录，skynet的所有代码不作改动，通用的写到common
脚本放到项目下script
```

## 服务处理call和send的情况
    util提供util.ret这个方法，对skynet.ret进行了一次封装，默认情况下以call处理，以skynet.ret(skynet.pack(...))返回  
    当处理消息的方法返回的是util.NORET，表示发送方以send的方式发送，本服务不作回应  
    
    local skynet = require "skynet"
    local util = require "util"
    local CMD = {}
    function CMD.on_send()
        return util.NORET
    end
    function CMD.on_call()
        return
    end
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd)
            local f = assert(CMD[cmd], cmd)
            util.ret(f(...))
        end)
    end)

## logger服务
    文件fd，保存一段时间，自动关闭
    系统log分系统存, 一天一份日志
    玩家log分uid存，一天一份日志
    所有的日志都会用统一再输出到总日志里，终端模式下标准输出，或者写到skynet配置的logpath目录下
    
## sname服务
    定义一些常用的服务，第一次引用的时候创建一个unique服务，同一节点通用，通常还会再封装一层api。参照MONGO的用法。   
    
## 通用的节点
    monitor监视节点，所有需要监视的节点在启动后要向monitor上报节点配置，运行性能  
    https://github.com/zhandouxiaojiji/monitor.git
    share公共数据节点，节点间数据共享  
    https://github.com/zhandouxiaojiji/share.git

## 通用的服务
```
alert         警报系统（已接钉钉api)
gm            通用的gm服务
logger        日志服务
proto_env     节点内共享protobuf数据
publish       部署发布服务
report        报告monitor
stop          停机服务
db/mongod     访问mongo
db/redisd     访问redis
db/mysqld     访问mysql
web/webclient http客户端，支持http/https, GET/POST
web/webclient http服务端，支持http(不支持https，需要nginx转发), GET/POST
ws/watchdog   websocket侦听服务(不支持wss，需要nginx转发)
ws/agent      websocket消息代理，多个玩家共享，可配置
sock/watchdog socket侦听服务
sock/agent    socket消息代理，多个玩家共享，可配置
```

## watchdog/agent
代码里有很多对watchdog/agent，它们是专门用来监听和代发消息的服务，上层逻辑可以根据需求选择，不需要重复写这部分代码。每个agent是都会启动一个虚拟机，但是可以多个玩家共用一个agent，每个agent可配置最大玩家数，预加载一些，不够会自动创建，峰值过后agent不释放。如此设计主要是考虑到利用多核又不消耗过多的内存（一人一agent的土豪可以直接忽略）

## 停机方法
目前skynet只有在logger服务捕捉SIGHUP信号，其它信号需要写C服务，后续再加上  
如需要安全停机:  
```
local log = require "log"
log.sighup() -- 向logger注册信号处理服务
skynet.dispatch("lua", function(_, _, cmd)
    if cmd == "SIGHUP" then
    	-- todo save data
        skynet.abort()
    end
end) 
```
## GM系统
按模块添加方法集，然后在后台输入命令
```
local gm = require "gm"
gm.add_gmcmd("test_module", "test_cmd")
```
## 创建一个websocket监听服务
	-- gamesvr.gamesvr 和 gamesvr.player分别为游戏服逻辑和玩家逻辑
	local game = skynet.newservice("ws/watchdog", "gamesvr.gamesvr", "gamesvr.player")
    skynet.call(game, "lua", "start", {
        port = 8002, -- 监听端口
        preload = 10, -- agent预加载数 
        proto = conf.workspace.."script/def/proto/package.pb", -- pb文件路径
        send_type = "text", -- websock类型 text/binary
    })

## 发布到远程服务器
在项目的script/publish/conf目录下创建需要发布的配置，克隆一份conf，修改部分参数，运行shell/publish.sh进行发布，具体参照share节点

## 活动日程
schedule是一个专门负责定时执行的服务，调试方便，特别适合做活动开放的日程  
```
skynet.fork(function()
    while true do
        schedule.submit({mon = 10, day = 1})
        -- todo 国庆活动
        skynet.sleep(100)
    end
end)
schedule.changetime({mon = 9, day = 30, hour = 23, min = 59, sec = 59})
```
