local skynet    = require "skynet"
local util      = require "util"

local battle_path = ...
local battle_t = require(battle_path)

local map = {}
local function create(battle_id)
   local battle = battle_t.new(battle_id, function()
        map[battle_id] = nil  
   end)
   map[battle_id] = battle
   return battle
end

local function destroy(battle_id)
    map[battle_id] = nil
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, battle_id, cmd, ...)
        local battle = map[battle_id] or create(battle_id)
        local f = assert(battle[cmd], cmd)
        util.ret(f(battle, ...))
        if cmd == "destroy" then
            destroy(battle_id)    
        end
    end)
end)

