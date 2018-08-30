# 基于skynet的通用服务器
  方便多个项目一起维护，支持sock,web,websock
# 项目结构
```
3rd(第三方库,非必要)
common(通用模块,本库)
    luaclib(编译好的c库)
    lualib-src(c库源码)
    lualib(lua库)
    service(通用服务)
skynet(fork skynet项目，不作任何改动)
test(项目例子,https://github.com/zhandouxiaojiji/test.git)
    sample
proj(你的项目)
    xxgame
        lualib(项目lua库)
        service(项目用到的服务)
        script(项目的逻辑脚本)
    monitor
    share
```
# 配置
```
mkdir workspace
cd workspace
git clone https://github.com/zhandouxiaojiji/common.git
git clone https://github.com/zhandouxiaojiji/skynet.git
git clone https://github.com/zhandouxiaojiji/test.git
mkdir proj #项目目录，参考test
cd skynet && make linux
cd ..
cd test/sample/shell
sh etc.sh game gamed #生成启动配置, etc.sh [配置名] [启动脚本] [是否以进程的方式启动]
./run.sh game #启动进程, run.sh [配置名]
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
