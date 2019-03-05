# skynet通用模块
  skynet官方并没有提供多少游戏相关的解决方案，我造了些轮子，勉强能用吧~
## 项目结构
项目结构可以参照[bewater-sample](https://github.com/zhandouxiaojiji/bewater-sample)，或者以第三方库的形式引入你的项目。我们有时候需要同时维护多个新老项目，我把通用部分抽离出来，一方面是为了让旧项目与新代码保持同步，另一方面为了降低新建项目的成本，做到开箱即用。
```
bewater(通用模块,本仓库) https://github.com/zhandouxiaojiji/bewater.git
    examples(测试服务)
    luaclib(编译好的c库)
    lualib-src(c库源码)
    lualib(lua库)
      bw(一些常用的lua库)
      sys(一些业务相关的系统，可以忽略)
      def(一些定义，在你的项目里把它覆盖）
    service(通用服务)
    etc(测试启动配置)
    shell(测试启动脚本)
    script(测试脚本)
    examples(测试服务)
skynet(fork skynet项目，不作任何改动) https://github.com/zhandouxiaojiji/skynet.git  
proj
    xxgame(你的项目)
        lualib(项目lua库)
        service(项目用到的服务)
        script(项目的逻辑脚本)
    bewater-monitor(监视节点) https://github.com/zhandouxiaojiji/bewater-monitor.git
    bewater-share(数据共享节点) https://github.com/zhandouxiaojiji/bewater-share.git
    bewater-backup(备份节点) https://github.com/zhandouxiaojiji/bewater-backup.git
    bewater-test(测试节点) https://github.com/zhandouxiaojiji/bewater-test.git
```
## 配置
```
mkdir workspace
cd workspace
git clone https://github.com/zhandouxiaojiji/bewater.git
git clone https://github.com/zhandouxiaojiji/skynet.git
mkdir proj #项目目录，参考monitor和share
cd bewater/shell
./etc.sh test test #生成启动配置, etc.sh [配置名] [启动脚本] [集群名] [是否以进程的方式启动]
./run.sh test #启动进程, run.sh [配置名]
```
## 脚本与服务检索优先级
项目>bewater>skynet  
这三个目录下都有luaclib,lualib-src,lualib,service这几个目录，skynet的所有代码不作改动，通用的写到bewater  
服务的检索分两种，service/?.lua和service/?/init.lua，可以服务写成一个脚本，放在service下，或者写成一个目录，入口文件是init.lua，服务内require优先查找当前目录，参考service/sock/hall

## lua库
```
bw.bewater    框架相关api
bw.timer 		  定时器
bw.uuid 		  生成唯一uuid
bw.lock 		  协程锁
bw.hotfix 		热更
bw.hash_array 同时具有哈希和数组特性的结构体
bw.const 		  给table添加只读限制
bw.class 		  类
bw.bash 		  执行系统命令
bw.xml 		    xml库
bw.web        http相关库
bw.payment 	  支付宝支付&微信支付&苹果支付
bw.ip  	      ip相关api
bw.auth.wx 		微信api
```

## c库
```
cjson 		  json库
codec 		  集成md5,rsa,base64,aes等编码加解密算法
protobuf 	  pb库
random 		  随机库
webclient 	http库
```

## 通用的服务
```
alert         警报系统（已接企业微信api)
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
web/webserver http服务端，支持http(不支持https，需要nginx转发), GET/POST
ws/watchdog   websocket侦听服务(不支持wss，需要nginx转发)
ws/agent      websocket消息代理，多个玩家共享，可配置
sock/hall     socket侦听服务
sock/agent    socket消息代理，多个玩家共享，可配置
```

## 服务处理call和send的情况
    bewater提供bewater.ret这个方法，对skynet.ret进行了一次封装，默认情况下以call处理，以skynet.retpack(...)返回  
    当处理消息的方法返回的是util.NORET，表示发送方以send的方式发送，本服务不作回应  
    
    local skynet = require "skynet"
    local bewater = require "bw.bewater"
    local CMD = {}
    function CMD.on_send()
        return bewater.NORET
    end
    function CMD.on_call()
        return
    end
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd)
            local f = assert(CMD[cmd], cmd)
            bewater.ret(f(...))
        end)
    end)

## logger服务
    文件fd，保存一段时间，自动关闭
    系统log分系统存, 一天一份日志
    玩家log分uid存，一天一份日志
    所有的日志都会用统一再输出到总日志里，终端模式下标准输出，或者写到skynet配置的logpath目录下
    
## sname服务
    定义一些常用的服务，第一次引用的时候创建一个unique服务，同一节点通用，通常还会再封装一层api。参照MONGO的用法。   

## 停机方法
目前skynet只有在logger服务捕捉SIGHUP信号，其它信号需要写C服务，后续再加上  
如需要安全停机:  
```
local log = require "bw.log"
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
local gm = require "bw.gm"
gm.add_gmcmd("test_module", "test_cmd")
```

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

## 定时器
skynet的timeout本身不支持取消，而且每个timeout都会新建一条协程，但是游戏通常需要用大量的定时器。所以我对根据云风大神建议对skynet的timeout进行了封装，以单向链表的数据结构记录时间和回调。timer库可以创建大量的定时器，销毁也比较方便，最好是在同个虚拟机或者单个玩家的对象只挂一个timer，这样比较省资源，也比较方便管理。后续会参照日程表schedule加入修改系统时间的方法，让调试更加方便。
```
local timer = require "bw.timer"
local ti = timer.create()
ti.delay(1, function()
    -- todo timeout
end)
ti.delay(5.5, function()
    -- todo timeout
end)
ti.destroy()
```
## 网页后台管理
之前写过一版简单的[skynet-webconsole](https://github.com/zhandouxiaojiji/webconsole)，新版还在开发([skynet-cms-layui](https://github.com/zhandouxiaojiji/skynet-cms-layui))
![preview2](https://github.com/zhandouxiaojiji/webconsole/blob/master/images/preview1.jpg)
## 优化与改进计划
+ 最初的思路是设计各种通用的服务，然后暴露一些接口给使用者，这种设计思路其实是错误的。应该把通用的逻辑抽成lua库，让使用者自己制定服务，参照云风写的agent和gateserver二者的关系。后续将逐步消灭service目录下的服务，改成lualib。
+ 带业务逻辑的服务应该写成目录的形式(即service/?/init.lua)，这样可以保证服务内部api的私有性，不用写在lualib跟其它服务的逻辑混淆。
+ mongo的数据读写使用orm模块进行严格检查
+ 日志系统改用rsyslog
## 关于bewater
Be water My friend 是在我心目中浩气长存的伟大武术家李小龙先生已经解释过啦，如果你想更加了解多点的话，不妨一起探讨一下。(QQ:1013299930)
