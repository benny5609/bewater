local skynet    = require "skynet"
local packet    = require "bw.sock.packet"
local bewater   = require "bw.bewater"
local protobuf  = require "bw.protobuf"
local log       = require "bw.log"

local trace = log.trace("agent")

local player_path = ...
local player_t = require(player_path)

local WATCHDOG
local GATE
local MAX_COUNT

local CMD = {}
local fd2player = {}
local uid2player = {}
local count = 0

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (buff, sz)
		return packet.unpack(buff, sz)
	end,
	dispatch = function (fd, _, ...)
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
        local player = assert(fd2player[fd], "player not exist, fd:"..fd)
        player.net:recv(...)
	end
}

function CMD.init(gate, watchdog, max_count, proto)
    GATE = assert(gate)
    WATCHDOG = assert(watchdog)
    MAX_COUNT = max_count or 100
    protobuf.register_file(proto)
end

function CMD.stop()
    for _, player in pairs(uid2player) do
        bewater.try(function()
            player:offline()
        end)
    end
    skynet.call(WATCHDOG, "lua", "free_agent", skynet.self())
end

-- from watchdog
function CMD.new_player(fd, ip)
    local player = player_t.new()
    player.net:init(WATCHDOG, GATE, skynet.self(), fd, ip)
    fd2player[fd] = player
	skynet.call(GATE, "lua", "forward", fd)
    count = count + 1
    return count >= MAX_COUNT
end

-- from watchdog
function CMD.socket_close(_, fd)
    local player = assert(fd2player[fd], fd)
    trace("socket_close player:%s, old_fd:%s, new_fd:%s", player, player.net:get_fd(), fd)
    if player.net:get_fd() == fd then
        player:offline()
    end
    fd2player[fd] = nil
end

-- from player
function CMD.player_online(uid, fd)
    local player = assert(fd2player[fd])
    trace("player_online, player:%s, uid:%s, fd:%s", player, uid, fd)
    uid2player[uid] = player
end

-- from player
function CMD.free_player(uid)
    trace("free_player, player:%s, uid:%s", uid2player[uid], uid)
    uid2player[uid] = nil
    if count == MAX_COUNT then
        skynet.call(WATCHDOG, "lua", "set_free", skynet.self())
    end
    count = count - 1
end

function CMD.reconnect(fd, uid, csn, ssn, passport, user_info)
    local player = uid2player[uid]
    if not player then
        return
    end
    --local old_fd = player.net:get_fd()
    if player.net:reconnect(fd, csn, ssn, passport, user_info) then
        --fd2player[old_fd] = nil
        fd2player[fd] = player
	    skynet.call(GATE, "lua", "forward", fd)
        return player:base_data()
    end
end

function CMD.kick(uid)
    local player = uid2player[uid]
    if player then
        player:kickout()
        uid2player[uid] = nil
    end
end

local function check_timeout()
    for _, player in pairs(uid2player) do
        if player.check_timeout then
            bewater.try(function()
                player:check_timeout()
            end)
        end
    end
end

function CMD.online_count()
    local i = 0
    for _, player in pairs(uid2player) do
        if player.is_online then
            --trace("player online, player:%s, uid:%s", player, player.uid)
            i = i + 1
        end
    end
    return i
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, arg1, arg2, arg3, ...)
        local f = CMD[arg1]
        if f then
            bewater.ret(f(arg2, arg3, ...))
        else
            --local player = assert(uid2player[arg1], string.format("%s %s %s", arg1, arg2, arg3))
            local player = uid2player[arg1]
            if not player then
                -- todo fix this bug
                return bewater.ret()
            end
            local module = assert(player[arg2], arg2)
            if type(module) == "function" then
                bewater.ret(module(player, arg3, ...))
            else
                bewater.ret(module[arg3](module, ...))
            end
        end
    end)

    -- 定时检查超时，一分钟误差，如需要精准的触发，使用日程表schedule
    skynet.fork(function()
        while true do
            check_timeout()
            skynet.sleep(60*100)
        end
    end)
end)
