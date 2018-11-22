-- 文件fd，保存一段时间，自动关闭
-- 系统log分系统存, 一天一份日志
-- 玩家log分uid存，一天一份日志
--

local Skynet        = require "skynet.manager"
local DateHelper    = require "util.date_helper"
local Conf          = require "conf"
local Sname         = require "sname"
require "bash"

local errfile = io.open(string.format("%s/log/%s.log", 
    Conf.workspace, Conf.clustername or "error"), "w+")

local function write_log(file, addr, str)
    local str = string.format("[%08x][%s] %s", addr, os.date("%Y-%m-%d %H:%M:%S", os.time()), str) 
    if string.match(str, "\n(%w+ %w+)") == "stack traceback" then
        if Conf.alert and Conf.alert.enable then
            Skynet.send(Sname.ALERT, "lua", "traceback", str)
        end
    end

    if file == errfile then
        print(str)
    end

    file:write(str.."\n")
    file:flush()
end

local logs = {} -- key(sys or uid) -> {last_time, file}
local CMD = {}
function CMD.trace(addr, sys, str)
    local str = string.format("[%s] %s", sys, str) 
    local log = logs[sys]
    if not log or DateHelper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        bash("mkdir -p %s/log/%s", Conf.workspace, sys)
        local filename = string.format("%s/log/%s/%s.log", 
            Conf.workspace, sys, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[sys] = log
    end
    log.last_time = os.time()

    write_log(log.file, addr, str)
    write_log(errfile, addr, str) 
end

function CMD.player(addr, uid, str)
    local str = string.format("[%d] %s", uid, str) 
    local log = logs[uid]
    if not log or DateHelper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        local dir = string.format("%d/%d/%d", uid//1000000, uid%1000000//1000, uid%1000)
        bash("mkdir -p %s/log/player/%s", Conf.workspace, dir)
        local filename = string.format("%s/log/player/%s/%s.log", 
            Conf.workspace, dir, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[uid] = log
    end
    log.last_time = os.time()

    write_log(log.file, addr, str)
    write_log(errfile, addr, str) 
end

local sighup_addr = nil
function CMD.register_sighup(addr)
    assert(not sighup_addr, "already register sighup")
    sighup_addr = addr
end

Skynet.register_protocol {
    name = "text",
    id = Skynet.PTYPE_TEXT,
    unpack = Skynet.tostring,
    dispatch = function(_, addr, str)
        write_log(errfile, addr, str) 
    end
}

-- 捕捉sighup信号(kill -1)
Skynet.register_protocol {
    name = "SYSTEM",
    id = Skynet.PTYPE_SYSTEM,
    unpack = function(...) return ... end,
    dispatch = function(...)
        -- reopen signal
        if sighup_addr then
            Skynet.send(sighup_addr, "lua", "SIGHUP")
        else
            Skynet.error("handle SIGHUP, skynet will be stop")
            Skynet.abort()
        end
    end
}

Skynet.start(function()
    Skynet.register ".logger"
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        assert(CMD[cmd], cmd)(...)
        -- no return, don't call this service, use send
    end)
    Skynet.fork(function()
        while true do
            local cur_time = os.time()
            for k, v in pairs(logs) do
                if cur_time - v.last_time > 3600 then
                    v.file:close()
                    logs[k] = nil
                end
            end
            Skynet.sleep(100)
        end
    end)
end)
