local skynet = require "skynet"
local autoid = require "share.autoid"
local util   = require "util"

local agents = {}
local id2agent = {} -- battle_id -> agent
local balance = 1

local CMD = {}
function CMD.init(battle_path, preload)
    preload = preload or 10
    for i = 1, preload do
        agents[i] = skynet.newservice("battle/agent", battle_path)
    end
end

function CMD.create_battle()
    balance = balance + 1
    if balance > #agents then
        balance = 1
    end
    local battle_id = autoid.create()
    local agent = agents[balance]
    id2agent[battle_id] = agent
    return battle_id, agent
end

function CMD.destroy_battle(battle_id)
    local agent = id2agent[battle_id]
    skynet.call(agent, "lua", "destroy", battle_id)
    id2agent[battle_id] = nil
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)

