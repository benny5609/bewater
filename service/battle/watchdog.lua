local Skynet = require "skynet"
local Autoid = require "share.autoid"
local Util   = require "util"

local agents = {}
local id2agent = {} -- battle_id -> agent
local balance = 1

local CMD = {}
function CMD.init(battle_path, preload)
    preload = preload or 10
    for i = 1, preload do
        agents[i] = Skynet.newservice("battle/agent", battle_path)
    end
end

function CMD.create_battle()
    balance = balance + 1
    if balance > #agents then
        balance = 1
    end
    local battle_id = Autoid.create()
    local agent = agents[balance]
    id2agent[battle_id] = agent
    return battle_id, agent
end

function CMD.destroy_battle(battle_id)
    local agent = id2agent[battle_id]
    Skynet.call(agent, "lua", "destroy", battle_id)
    id2agent[battle_id] = nil
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
end)

