local skynet        = require "skynet"
local socket        = require "skynet.socket"
local json          = require "cjson"
local util          = require "util"
local opcode        = require "def.opcode"
local errcode       = require "def.errcode"
local protobuf      = require "protobuf"

local player_path   = ...
local player_t      = require(player_path)

local WATCHDOG
local MAX_COUNT

local send_type -- text/binary
local CMD = {}
local fd2player = {}
local uid2player = {}
local count = 0


function CMD.new_player(fd, ip)
    socket.start(fd)
    local player = player_t.new()
    player.net:init(WATCHDOG, skynet.self(), fd, ip)
    fd2player[fd] = player
    count = count + 1
    return count >= MAX_COUNT
end

function CMD.init(watchdog, max_count, proto)
    WATCHDOG = assert(watchdog)
    MAX_COUNT = max_count or 100
    if proto then
        protobuf.register_file(proto)
    end
end

function CMD.stop()
    for _, player in pairs(uid2player) do
        util.try(function()
            player:kick(errcode.SERVER_STOP)
            player:offline() 
        end)
    end
    skynet.call(WATCHDOG, "lua", "free_agent", skynet.self())
end

-- from player
function CMD.player_online(uid, fd)
    local player = assert(fd2player[fd])
    uid2player[uid] = player
end

function CMD.free_player(uid)
    uid2player[uid] = nil
    if count == MAX_COUNT then
        skynet.call(WATCHDOG, "lua", "set_free", skynet.self())
    end
    count = count - 1
end

-- from watchdog
function CMD.socket_close(fd)
    local player = assert(fd2player[fd])
    player:offline()
    fd2player[fd] = nil
end

function CMD.reconnect(uid, csn, ssn)
    local player = uid2player[uid]
    if not player then
        return
    end
    fd2player[player.net:get_fd()] = nil
    return player.net:reconnect(csn, ssn)
end

function CMD.kick(uid)
    local player = uid2player[uid]
    if player then
        player:kick(errcode.KICK)
        uid2player[uid] = nil
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, arg1, arg2, arg3, ...)
        local conf = require "conf"
        local f = CMD[arg1]
        if f then
            util.ret(f(arg2, arg3, ...))
        else
            local player = assert(uid2player[arg1], arg1)
            local module = assert(player[arg2], arg2)
            if type(module) == "function" then
                util.ret(module(player, arg3, ...))
            else
                util.ret(module[arg3](module, ...))
            end
        end
    end)
end)

