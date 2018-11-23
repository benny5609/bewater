local Skynet    = require "skynet.manager"
local Mysql     = require "skynet.db.mysql"
local Util      = require "util"
local Conf      = require "conf"

local mod = ...

if mod == "agent" then

local db
Skynet.start(function()
    local function on_connect(_db)
        _db:query("set charset utf8")
    end
    db=Mysql.connect({
        host=Conf.mysql.host,
        port=Conf.mysql.port,
        database=Conf.mysql.name,
        user=Conf.mysql.user,
        password=Conf.mysql.password,
        max_packet_size = 1024 * 1024,
        on_connect = on_connect
    })
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(db[cmd])
        local ret = f(db, ...)
        assert(not ret.err,string.format("mysql error:%s\n%s", table.pack(...)[1], Util.dump(ret)))
        Util.ret(ret)
    end)
end)

else

Skynet.start(function()
    local preload = Conf.preload or 10
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
        Util.ret(ret)
    end)
end)

end
