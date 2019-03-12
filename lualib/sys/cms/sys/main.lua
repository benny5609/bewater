local date_helper   = require "bw.util.date_helper"
local conf          = require "conf"

return function()
    local info = require "bw.util.clusterinfo"
    local profile = info.profile
    return {
        online = 0,
        run_time = date_helper.format_now(),
        list = {
            {k = "项目", v = conf.desc or "未知"},
            {k = "节点", v = conf.clustername or "未知"},
            {k = "外网ip", v = info.pnet_addr or "未知"},
            {k = "内网ip", v = info.inet_addr or "未知"},
            {k = "进程号", v = info.pid or "未知"},
            {k = "性能", v = profile and string.format("CPU:%sMEM:%.fM",
                profile.cpu, profile.mem/1024) or "未知"},
            {k = "监听端口", v = conf.gate and string.format("%s:%s",
                conf.gate.host, conf.gate.port) or "未知"},
            {k = "后台地址", v = conf.webconsole and string.format("%s:%s",
                conf.webconsole.host, conf.webconsole.port) or "未知"},
            {k = "mongo", v = conf.mongo and string.format("%s:%s[%s]",
                conf.mongo.host, conf.mongo.port, conf.mongo.name) or "未知"},
            {k = "redis", v = conf.redis and string.format("%s:%s",
                conf.redis.host, conf.redis.port) or "未知"},
            {k = "mysql", v = conf.mysql and string.format("%s:%s[%s]",
                conf.mysql.host, conf.mysql.port, conf.mysql.name) or "未知"},
            {k = "警报", v = (conf.alert and conf.alert.enable) and "已开启" or "未开启"},
        },
    }
end
