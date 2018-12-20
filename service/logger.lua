-- 文件fd，保存一段时间，自动关闭
-- 系统log分系统存, 一天一份日志
-- 玩家log分uid存，一天一份日志
--

local skynet        = require "skynet.manager"
local date_helper   = require "bw.util.date_helper"
local conf          = require "conf"
local sname         = require "bw.sname"
require "bw.bash"

local mainfile = io.open(string.format("%s/log/%s.log",
    conf.workspace, conf.clustername), "w+")
local errfile = io.open(string.format("%s/log/error.log",
    conf.workspace), "a+")

local function write_log(file, addr, str)
    str = string.format("[%08x][%s] %s", addr, os.date("%Y-%m-%d %H:%M:%S", os.time()), str)
    if string.match(str, "\n(%w+ %w+)") == "stack traceback" then
        if conf.alert and conf.alert.enable then
            skynet.send(sname.ALERT, "lua", "traceback", str)
        end
        errfile:write(str.."\n")
        errfile:flush()
    end

    if file == mainfile then
        print(str)
    end

    file:write(str.."\n")
    file:flush()
end

local logs = {} -- key(sys or uid) -> {last_time, file}
local CMD = {}
function CMD.error(addr, str)
    print(str)
    write_log(errfile, addr, str)
end

function CMD.trace(addr, sys, str)
    str = string.format("[%s] %s", sys, str)
    local log = logs[sys]
    if not log or date_helper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        bash("mkdir -p %s/log/%s", conf.workspace, sys)
        local filename = string.format("%s/log/%s/%s.log",
            conf.workspace, sys, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[sys] = log
    end
    log.last_time = os.time()

    write_log(log.file, addr, str)
    write_log(mainfile, addr, str)
end

function CMD.player(addr, uid, str)
    str = string.format("[%d] %s", uid, str)
    local log = logs[uid]
    if not log or date_helper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        local dir = string.format("%d/%d/%d", uid//1000000, uid%1000000//1000, uid%1000)
        bash("mkdir -p %s/log/player/%s", conf.workspace, dir)
        local filename = string.format("%s/log/player/%s/%s.log",
            conf.workspace, dir, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[uid] = log
    end
    log.last_time = os.time()

    write_log(log.file, addr, str)
    write_log(mainfile, addr, str)
end

local sighup_addr = nil
function CMD.register_sighup(addr)
    assert(not sighup_addr, "already register sighup")
    sighup_addr = addr
end

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, addr, str)
        write_log(mainfile, addr, str)
    end
}

-- 捕捉sighup信号(kill -1)
skynet.register_protocol {
    name = "SYSTEM",
    id = skynet.PTYPE_SYSTEM,
    unpack = function(...) return ... end,
    dispatch = function()
        -- reopen signal
        if sighup_addr then
            skynet.send(sighup_addr, "lua", "SIGHUP")
        else
            skynet.error("handle SIGHUP, skynet will be stop")
            skynet.abort()
        end
    end
}

skynet.start(function()
    skynet.register ".logger"
    skynet.dispatch("lua", function(_, _, cmd, ...)
        assert(CMD[cmd], cmd)(...)
        -- no return, don't call this service, use send
    end)
    skynet.fork(function()
        while true do
            local cur_time = os.time()
            for k, v in pairs(logs) do
                if cur_time - v.last_time > 3600 then
                    v.file:close()
                    logs[k] = nil
                end
            end
            skynet.sleep(100)
        end
    end)
end)
