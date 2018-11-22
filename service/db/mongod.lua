local Skynet = require "skynet.manager"
local Mongo  = require "skynet.db.mongo"
local Util   = require "util"
local Conf   = require "conf"

local mod = ...

if mod == "agent" then

local db
local CMD = {}
function CMD.find_one(name, query, selector)
    local data = db[name]:findOne(query, selector)
    return Util.str2num(data)
end

function CMD.find_one_with_default(name, query, default, selector)
    local data = db[name]:findOne(query, selector)
    if not data then
        CMD.insert(name, default)
        return default
    end
    return Util.str2num(data)
end

function CMD.find(name, query, selector)
    local ret = db[name]:find(query, selector)
    local data = {}
    while ret:hasNext() do
        table.insert(data, ret:next())
    end
    return Util.str2num(data)
end

function CMD.update(name, query_tbl, update_tbl)
    update_tbl = Util.num2str(update_tbl)
    local ok, err, r = db[name]:findAndModify({query = query_tbl, update = update_tbl})
    if not ok then
        Skynet.error("mongo update error")
        Util.printdump(r)
        error(err)
    end
    return true
end

function CMD.insert(name, tbl)
    tbl = Util.num2str(tbl)
    local ok, err, r = db[name]:safe_insert(tbl)
    if not ok then
        Skynet.error("mongo update error")
        Util.printdump(r)
        error(err)
    end
    return true
end

function CMD.delete(name, query_tbl)
    local ok, err, r = db[name]:delete(query_tbl)
    if not ok then
        Skynet.error("mongo update error")
        Util.printdump(r)
        error(err)
    end
    return true
end

function CMD.drop(name)
    return db[name]:drop()
end

function CMD.get(key, default)
    local ret = db.global:findOne({key = key})
    if ret then
        return Util.str2num(ret.value)
    else
        db.global:safe_insert({key = key, value = default})
        return default
    end
end

function CMD.set(key, value)
    db.global:findAndModify({
        query = {key = key},
        update = {key = key, value = value},
    })
end

Skynet.start(function()
    db = Mongo.client(Conf.mongo)[Conf.mongo.name]
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], ...)
        Util.ret(f(...))
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
