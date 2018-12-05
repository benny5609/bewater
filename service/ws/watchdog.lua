local skynet        = require "skynet"
local socket        = require "skynet.socket"
local bewater       = require "bewater"

local server_path, player_path = ...
assert(server_path) -- 服务器逻辑(xxx.xxxserver)
assert(player_path) -- 玩家逻辑(xxx.xxxplayer)

local server = require(server_path)

local uid2agent = {}    -- 每个账号对应的agent
local free_agents = {}  -- 空闲的agent addr -> true
local full_agents = {}  -- 满员的agent addr -> true

local PLAYER_PER_AGENT  -- 每个agent支持player最大值
local PROTO

local function create_agent()
    local agent = skynet.newservice("ws/agent", player_path)
    skynet.call(agent, "lua", "init", skynet.self(), PLAYER_PER_AGENT, PROTO)
    free_agents[agent] = true
    return agent
end

local CMD = {}
function CMD.start(conf)
    PLAYER_PER_AGENT = conf.player_per_agent or 100
    PROTO = conf.proto

    server:start()

    local preload = conf.preload or 10     -- 预加载agent数量
    for i = 1, preload do
        create_agent()
    end

    local address = "0.0.0.0:"..conf.port
    skynet.error("Listening "..address)
    local fd = assert(socket.listen(address))
    socket.start(fd , function(_fd, addr)
        local agent = next(free_agents)
        if not agent then
            agent = create_agent()
        end
        if skynet.call(agent, "lua", "new_player", _fd, addr) then
            -- agent已经满
            free_agents[agent] = nil
            full_agents[agent] = true
        end
    end)
end

function CMD.stop()
    for agent, _ in pairs(free_agents) do
        skynet.send(agent, "lua", "stop")
    end
    for agent, _ in pairs(full_agents) do
        skynet.send(agent, "lua", "stop")
    end
    while true do
        local count = 0
        for _, v in pairs(free_agents) do
            count = count + 1
        end
        for _, v in pairs(full_agents) do
            count = count + 1
        end
        skynet.error(string.format("left agent:%d", count))
        if count == 0 then
            return
        end
        skynet.sleep(10)
    end
end

function CMD.set_free(agent)
    free_agents[agent] = true
    full_agents[agent] = nil
end

function CMD.free_agent(agent)
    free_agents[agent] = nil
    full_agents[agent] = nil
end

-- 上线后agent绑定uid，下线缓存一段时间
function CMD.player_online(agent, uid)
    uid2agent[uid] = agent
end

-- 下线一段时间后调用
function CMD.player_destroy(agent, uid)
    uid2agent[uid] = nil
    free_agents[agent] = true
    full_agents[agent] = nil
end

function CMD.reconnect(uid, csn, ssn)
    local agent = uid2agent[uid]
    if agent then
        return agent, skynet.call(agent, "lua", "reconnect", uid, csn, ssn)
    end
end

function CMD.kick(uid)
    local agent = uid2agent[uid]
    if agent then
        skynet.call(agent, "lua", "kick", uid)
        uid2agent[uid] = nil
    end
end

function CMD.online_count()
    local count = 0
    for v, _ in pairs(free_agents) do
        count = count + skynet.call(v, "lua", "online_count")
    end
    for v, _ in pairs(full_agents) do
        count = count + skynet.call(v, "lua", "online_count")
    end
    return count
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, ...)
        local f = CMD[cmd1] or server[cmd1]
        assert(f, cmd1)
        bewater.ret(f(...))
    end)
end)
