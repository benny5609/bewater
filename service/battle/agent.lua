local Skynet    = require "skynet"
local Util      = require "util"
local Errcode   = require "def.errcode"

local battle_path = ...
local battle_t = require(battle_path)

local battles = {}

local CMD = {}
function CMD.create(battle_id, mode)
    local battle = battle_t.new()
    battle:init_by_data({
        battle_id = battle_id,
        mode = mode
    })
    battles[battle_id] = battle
end

function CMD.destroy(battle_id)
    local battle = battles[battle_id]
    battle:destroy()
    battles[battle_id] = nil
end

function CMD.call_battle(battle_id, cmd, ...)
    local battle = battles[battle_id]
    if not battle then
        print("battle not exist", battle_id)
        return Errcode.BATTLE_NOT_EXIST
    end
    local f = assert(battle[cmd], cmd)
    return f(battle, ...)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
end)

