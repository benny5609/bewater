local Skynet = require "skynet.manager"
local Mongo  = require "db.mongo_helper"
local Util   = require "util"
local Def    = require "def"

local RESERVE_COUNT = 100
local INITIAL_ID = Def.INITIAL_ID or 10000000

local reserve_id
local id

local CMD = {}
function CMD.start()
    id = Mongo.get("autoid", INITIAL_ID)
    reserve_id = id + RESERVE_COUNT
end

function CMD.stop()
    Mongo.set("autoid", id)
end

function CMD.create(count)
    count = count or 1
    local start_id = id
    id = id + count
    if id > reserve_id then
        reserve_id = id + RESERVE_COUNT
        Mongo.set("autoid", reserve_id)
    end
    return start_id, count
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
    Skynet.register "autoid"
end)
