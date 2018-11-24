local Skynet    = require "skynet"
local Class     = require "class"
local Conf      = require "conf"
local Log       = require "log"
local Gm        = require "gm"

local trace = Log.trace("webconsole")

local M = Class("PlayerSkynet")
function M:ctor(player)
    self.player = player
end

local function debug_call(addr, cmd, ...)
    return Skynet.call(addr, "debug", cmd, ...)
end

function M:c2s_all_service()
    local list = {}

    local all = Skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = debug_call(addr, "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = debug_call(addr, "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = Skynet.address(addr)
    end
    table.sort(list, function(a, b)
        return a.addr < b.addr
    end)
    return {service_list = list}
end

function M:c2s_node_config()
    local info = require "util.clusterinfo"
    local profile = info.profile
    return {
        proj = Conf.proj,
        desc = Conf.desc,
        pnet_addr = info.pnet_addr,
        inet_addr = info.inet_addr,
        pid = info.pid,
        profile = profile and string.format("CPU:%sMEM:%.fM", profile.cpu, profile.mem/1024),
        gate = Conf.gate and string.format("%s:%s", Conf.gate.host, Conf.gate.port),
        webconsole = Conf.webconsole and string.format("%s:%s", Conf.webconsole.host, Conf.webconsole.port),
        mongo = Conf.mongo and string.format("%s:%s[%s]", Conf.mongo.host, Conf.mongo.port, Conf.mongo.name),
        redis = Conf.redis and string.format("%s:%s", Conf.redis.host, Conf.redis.port),
        mysql = Conf.mysql and string.format("%s:%s[%s]", Conf.mysql.host, Conf.mysql.port, Conf.mysql.name),
        alert_enable = Conf.alert and Conf.alert.enable,
    }
end

function M:c2s_get_blacklist()
    trace("get_blacklist")
    if not Conf.redis then
        return {list = "请配置redis数据库"}
    end
    local list = require "ip.blacklist"
    return {list = table.concat(list.list(), "\n")}
end

function M:c2s_set_blacklist(data)
    trace("set_blacklist")
    if not Conf.redis then
        return {list = "请配置redis数据库"}
    end
    local list = require "ip.blacklist"
    list.clear()
    for ip in string.gmatch(data.list, "[^\n]+") do
        trace("add black ip:%s", ip)
        list.add(ip)
    end
end

function M:c2s_get_whitelist()
    trace("get_blacklist")
    if not Conf.redis then
        return {list = "请配置redis数据库"}
    end
    local list = require "ip.whitelist"
    return {list = table.concat(list.list(), "\n")}
end

function M:c2s_set_whitelist(data)
    trace("set_blacklist")
    if not Conf.redis then
        return {list = "请配置redis数据库"}
    end
    local list = require "ip.whitelist"
    list.clear()
    for ip in string.gmatch(data.list, "[^\n]+") do
        trace("add black ip:%s", ip)
        list.add(ip)
    end
end

function M:c2s_run_gm(data)
    local time_str = string.format("[%s] ", os.date("%Y-%m-%d %H:%M:%S"))
    local args = {}
    for arg in string.gmatch(data.cmd, "[^ ]+") do
        table.insert(args, arg)
    end
    local modname = args[1]
    local cmd = args[2]
    if not modname or not cmd then
        return {ret = time_str.."格式错误"}
    end
    table.remove(args, 1)
    table.remove(args, 1)
    return {ret = time_str..Gm.run(modname, cmd, table.unpack(args))}
end

return M
