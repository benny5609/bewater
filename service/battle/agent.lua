local skynet    = require "skynet"
local util      = require "util"
local errcode   = require "def.errcode"

local battle_path = ...
local battle_t = require(battle_path)

local battles = {}

local CMD = {}
function CMD.create(battle_id, mode)
    print("&&&&&& create_battle", battle_id, mode)
    local battle = battle_t.new()
    battle:init_by_data({
        battle_id = battle_id,
        mode = mode
    })
    battles[battle_id] = battle
end

function CMD.destroy(battle_id)
    battles[battle_id] = nil
end

function CMD.call_battle(battle_id, cmd, ...)
    local battle = battles[battle_id]
    if not battle then
        return errcode.BattleNotExist
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)

