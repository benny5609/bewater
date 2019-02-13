local skynet = require "skynet.manager"
local mongo  = require "skynet.db.mongo"
local util   = require "bw.util"
local conf   = require "conf"

local mod = ...

if mod == "agent" then

local db
local CMD = {}
function CMD.find_one(name, query, selector)
    local data = db[name]:findOne(query, selector)
    return util.str2num(data)
end

function CMD.find_one_with_default(name, query, default, selector)
    local data = db[name]:findOne(query, selector)
    if not data then
        CMD.insert(name, default)
        return default
    end
    return util.str2num(data)
end

-- todo 此方法返回可能大于消息长度
function CMD.find(name, query, selector)
    local ret = db[name]:find(query, selector)
    local data = {}
    while ret:hasNext() do
        table.insert(data, ret:next())
    end
    return util.str2num(data)
end

function CMD.update(name, query_tbl, update_tbl)
    update_tbl = util.num2str(update_tbl)
    local ok, err, r = db[name]:findAndModify({query = query_tbl, update = update_tbl})
    if not ok then
        skynet.error("mongo update error")
        util.printdump(r)
        error(err)
    end
    return true
end

function CMD.insert(name, tbl)
    tbl = util.num2str(tbl)
    local ok, err, r = db[name]:safe_insert(tbl)
    if not ok then
        skynet.error("mongo update error")
        util.printdump(r)
        error(err)
    end
    return true
end

function CMD.delete(name, query_tbl)
    db[name]:delete(query_tbl)
    return true
end

function CMD.drop(name)
    return db[name]:drop()
end

function CMD.get(key, default)
    local ret = db.global:findOne({key = key})
    if ret then
        return util.str2num(ret.value)
    else
        db.global:safe_insert({key = key, value = default})
        return default
    end
end

function CMD.set(key, value)
    value = util.num2str(value)
    db.global:findAndModify({
        query = {key = key},
        update = {key = key, value = value},
    })
end

skynet.start(function()
    db = mongo.client(conf.mongo)[conf.mongo.name]
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], ...)
        util.ret(f(...))
    end)
end)

else

skynet.start(function()
    local preload = conf.preload or 10
    local agent = {}
    for i = 1, preload do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent")
    end
    local balance = 1
    skynet.dispatch("lua", function(_,_, ...)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
        local ret = skynet.call(agent[balance], "lua", ...)
        util.ret(ret)
    end)
end)

end
