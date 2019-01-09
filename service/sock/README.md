## hall服务
hall相当于watchdog，客户端连接上来会马上建立一个session，由sessions管理所有session，对应关系为fd->session，每个session对应一个visitor，
visitor对象处理玩家的登陆的逻辑(这个时候没有load角色数据)。登陆流程走完，由visitor调用sessions.forward_agent(...)，此时hall会将fd分配并转发给一个agent

## agent服务
一个agent服务会承载多个用户的，类似hall，agent也有users和user，对应关系为uid->user，每个user对应一个role，role对象处理玩家的上线后逻辑。session断开
或者重连的时候对user都没影响，只是更换fd

## Usage
```
local hall = skynet.newservice("sock/hall", "gamesvr", "role.role", "visitor") -- role和visitor需要使用者提供
skynet.call(hall, "lua", "start", {
    proto = conf.workspace.."/script/def/proto/package.pb",
    port = conf.gate.port,
    maxclient = conf.MAX_CLIENT,
    nodelay = true,
    preload = conf.gate.preload,
}, 20) 
```
## visitor规范
session收到的所有消息都会交由visitor处理，所以visitor需要提供如visitor.user.c2s_login这样跟协议名同名的api
```
local user = {}
user.__index = user
function user:c2s_login(data)
    --todo
    return 0
end
local function new_user(visitor)
    return setmetatable({
        visitor = visitor,
    }, user)
end

local mt = {}
mt.__index = mt
function mt:init(session)
    self.session = session
    self.user = new_user(self)
end
local M = {}
function M.new(session)
    local obj = setmetatable({}, mt) 
    obj:init(session)
    return obj 
end
return M
```

## role规范
同理visitor，role也需要提供跟协议名同名api，另外还需要提供以下接口
```
function role:online(...)
function role:offline(...)
function role:destroy(...)
```
