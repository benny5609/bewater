local skynet        = require "skynet"
local util          = require "util"
local log           = require "log"

local print         = log.print("match")
local trace         = log.trace("match")

local uid2info = {} -- uid -> info {uid, value, agent}
local values = {} -- value -> uids

local MODE       -- 匹配模式
local MAX_TIME   -- 匹配时长
local MAX_RANGE  -- 匹配最大范围

local CMD = {}
function CMD.init(mode, max_time, max_range)
    MODE = mode
    MAX_TIME = max_time or 3
    MAX_RANGE = max_range or 0
end

function CMD.start(uid, value, agent)
    print("start match", uid, value)
    if uid2info[uid] then
        skynet.error(uid, "is matching")
        return
    end
    uid2info[uid] = {
        uid = uid,
        value = value,
        agent = agent,
        ret = -1, -- -1:未匹配到对手 0:机器人 >0:玩家uid
    }
    values[value] = values[value] or {}
    values[value][uid] = os.time()
end

function CMD.reconnect(uid, agent)
    local info = uid2info[uid]
    if info then
        info.agent = agent
        return MODE
    end
end

function CMD.cancel(uid)
    print("cancel match", uid)
    local info = uid2info[uid]
    if not info then
        skynet.error(uid, "not matching")
        return
    end
    uid2info[uid] = nil
end

-- 最粗暴的匹配算法
local function update()
    if next(uid2info) then
        print("matching")
        --print(util.dump(uid2info))
    end
    local cur_time = os.time()
    for uid, info in pairs(uid2info) do
        local value = info.value
        if cur_time - values[value][uid] > MAX_TIME then
            info.ret = skynet.call("usercenter", "lua", "create_robot", value) -- 这个服务需要自定义
        else
            local list = {values[value]}
            for i = 1, MAX_RANGE do
                list[#list+1] = values[value - i]
                list[#list+1] = values[value + i]
            end
            for _, vs in pairs(list) do
                for u, _ in pairs(vs) do
                    if uid2info[u] and uid2info[u].ret < 0 and u ~= uid then
                        uid2info[u].ret = uid
                        info.ret = u
                        break
                    end
                end
                if info.ret >= 0 then
                    break
                end
            end
        end
    end

    for uid, info in pairs(uid2info) do
        if info.ret >= 0 then
            -- 随机位置
            local list = {uid, info.ret}
            local r = math.random(2)
            local id1 = list[r]
            local id2 = list[r==1 and 2 or 1]
            if uid2info[id1] then
                util.try(function()
                    skynet.call(uid2info[id1].agent, "lua", id1, "battle", "matched", MODE, id2)
                end)
            end
            if uid2info[id2] then
                util.try(function()
                    skynet.call(uid2info[id2].agent, "lua", id2, "battle", "matched", MODE, id1)
                end)
            end
            -- 创建战斗
            local battle_id, battle_agent = skynet.call("battlecenter", "lua", "create_battle")
            skynet.call(battle_agent, "lua", "create", battle_id, MODE)
            for idx, uid in pairs({id1, id2}) do
                local info = uid2info[uid]
                skynet.call(battle_agent, "lua", "call_battle", battle_id, "join", uid, idx, info and info.agent or nil)
                if uid2info[uid] then
                    uid2info[uid] = nil
                    values[info.value][uid] = nil
                end
            end
        end
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)

    skynet.fork(function()
        while true do
            util.try(function()
                update() 
            end)
            skynet.sleep(100)
        end
    end)
end)
