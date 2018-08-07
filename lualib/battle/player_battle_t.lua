local skynet = require "skynet"
local class = require "class"
local def = require "def"

local M = class("player_battle_t")
function M:ctor(player)
    self.player = assert(player, "battle need player")
    for _, t in pairs(def.BattleType) do
       local battle_class = require(def.BattleClass[t])
       self[t] = battle_class.new()
    end
end

function M:init_by_data(data)
    data = data or {}
end

function M:base_data()
    return {
    }
end

function M:match()

end


-- network
function M:c2s_match(data)

end

function M:c2s_create_room(data)

end

function M:c2s_ready(data)

end

function M:c2s_sync(data)

end

function M:c2s_giveup(data)

end

return M