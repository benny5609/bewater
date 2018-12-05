local Skynet    = require "skynet.manager"
local Redis     = require "skynet.db.redis"
local bewater   = require "bewater"
local conf      = require "conf"

local mod = ...

if mod == "agent" then

local db
Skynet.start(function()
    db = Redis.connect(conf.redis)
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        bewater.ret(db[cmd](db, ...))
    end)
end)

else

Skynet.start(function()
    local preload = conf.preload or 10
    local agent = {}
    for i = 1, preload do
        agent[i] = Skynet.newservice(SERVICE_NAME, "agent")
    end
    local balance = 1
    Skynet.dispatch("lua", function(_,_, ...)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
        local ret = Skynet.call(agent[balance], "lua", ...)
        bewater.ret(ret)
    end)
end)

end
