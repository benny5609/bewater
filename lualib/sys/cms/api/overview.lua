local date_helper   = require "bw.util.date_helper"
local conf          = require "conf"

return function()
    local info = require "bw.util.clusterinfo"
    local profile = info.profile
    return {
        online = 0,
        run_time = date_helper.format_now(),
        desc = conf.desc or "未知",
        clustername = conf.clustername or "未知",
        pnet_addr = info.pnet_addr or "未知",
        inet_addr = info.inet_addr or "未知",
        pid = info.pid or "未知",
        profile = profile and string.format("CPU:%sMEM:%.fM",
            profile.cpu, profile.mem/1024) or "未知",
        gate = conf.gate and string.format("%s:%s",
            conf.gate.host, conf.gate.port) or "未知",
        webconsole = conf.webconsole and string.format("%s:%s",
            conf.webconsole.host, conf.webconsole.port) or "未知",
        mongo = conf.mongo and string.format("%s:%s[%s]",
            conf.mongo.host, conf.mongo.port, conf.mongo.name) or "未知",
        redis = conf.redis and string.format("%s:%s",
            conf.redis.host, conf.redis.port) or "未知",
        mysql = conf.mysql and string.format("%s:%s[%s]",
            conf.mysql.host, conf.mysql.port, conf.mysql.name) or "未知",
        alert = (conf.alert and conf.alert.enable) and "已开启" or "未开启",
    }
end
