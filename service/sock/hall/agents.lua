local skynet     = require "skynet"
local bewater    = require "bw.bewater"
local hash_array = require "bw.hash_array"
local log        = require "bw.log"
local env        = require "env"

local trace = log.trace("agents")
local MAX_COUNT = 100 -- 每个agent最多负载人数
local agents = {}
local uid2agent = setmetatable({}, {__mode = "v"})

local function new_agent()
    trace("new_agent")
    local agent = bewater.protect {
        addr = skynet.newservice("sock/agent"),
        uids = hash_array.new()
    }
    skynet.call(agent.addr, "lua", "start", {
        role_path = env.ROLE,
        proto     = env.PROTO,
        gate      = env.GATE,
    })
    return agent
end

local function get_free_agent()
    for _, agent in pairs(agents) do
        if agent.uids:len() < MAX_COUNT then
            return agent
        end
    end
    local agent = new_agent()
    agents[agent.addr] = agent
    return agent
end

local M = {}
function M.forward(fd, uid, ip)
    local agent = uid2agent[uid]
    if not agent then
        agent = get_free_agent()
        agent.uids:add(uid)
        uid2agent[uid] = agent
    end
    skynet.call(agent.addr, "lua", "open", fd, uid, ip)
end

return M
