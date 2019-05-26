local skynet = require "skynet"
local util   = require "bw.util"

local tostring = tostring
local select   = select
local sformat  = string.format

local llevel_desc = {
    [0] = "EMG",
    [1] = "ALT",
    [2] = "CRI",
    [3] = "ERR",
    [4] = "WAR",
    [5] = "NTC",
    [6] = "INF",
    [7] = "DBG",
}

local llevel = {
    NOLOG    = 99,
    DEBUG    = 7,
    INFO     = 6,
    NOTICE   = 5,
    WARNING  = 4,
    ERROR    = 3,
    CRITICAL = 2,
    ALERT    = 1,
    EMERG    = 0,
}


local color = {
    red    = 31,
    green  = 32,
    blue   = 36,
    yellow = 33,
    other  = 37
}

local color_level_map = {
    [4] = "green",
    [5] = "blue",
    [6] = "other",
    [7] = "yellow",
}

local to_screen = false
if skynet.getenv("DEBUG") == "true" then
    to_screen = true
end

local function highlight(s, level)
    local c = color_level_map[level] or "red"
    return sformat("\x1b[1;%dm%s\x1b[0m", color[c], tostring(s))
end

local function format_log(addr, str)
    return sformat("[:%.8x] %s", addr, str)
end

local function syslog(level, str)
    str = format_log(skynet.self(), str)
    if to_screen then
        print(highlight(str, level))
    end
    skynet.send(".syslog", "lua", level, str)
end

local log = {}

function log.highlight(...)
    return highlight(...)
end

function log.format_log(...)
    return format_log(...)
end

function log.debug(...)

end

function log.debugf(fmt, ...)
    syslog(llevel.DEBUG, sformat(fmt, ...))
end

function log.info(...)

end

function log.infof(fmt, ...)
    syslog(llevel.INFO, sformat(fmt, ...))
end

function log.error(...)

end

function log.errorf(fmt, ...)
    syslog(llevel.ERROR, sformat(fmt, ...))
end

function log.warning(...)

end

function log.warningf(fmt, ...)
    syslog(llevel.WARNING, sformat(fmt, ...))
end

function log.syslog(level, str, addr)
    assert(llevel[level], level)
    syslog(level, str)
end

function log.dump(obj, depth)

end

return log
