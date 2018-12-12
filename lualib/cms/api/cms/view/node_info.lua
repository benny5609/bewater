local skynet = require "skynet"
local layui = require "cms.layui"
local conf = require "conf"
return function()
    local info = require "util.clusterinfo"
    local profile = info.profile
    local tbl = {
        {"项目", conf.desc or "未知"},
        {"节点", conf.clustername or "未知"},
        {"外网ip", info.pnet_addr or "未知"},
        {"内网ip", info.inet_addr or "未知"},
        {"进程号", info.pid or "未知"},
        {"性能", profile and string.format("CPU:%sMEM:%.fM", profile.cpu, profile.mem/1024) or "未知"},
        {"监听端口", conf.gate and string.format("%s:%s", conf.gate.host, conf.gate.port) or "未知"},
        {"后台地址", conf.webconsole and string.format("%s:%s", conf.webconsole.host, conf.webconsole.port) or "未知"},
        {"mongo", conf.mongo and string.format("%s:%s[%s]", conf.mongo.host, conf.mongo.port, conf.mongo.name) or "未知"},
        {"redis", redis = conf.redis and string.format("%s:%s", conf.redis.host, conf.redis.port) or "未知"},
        {"mysql", conf.mysql and string.format("%s:%s[%s]", conf.mysql.host, conf.mysql.port, conf.mysql.name) or "未知"},
        {"警报", (conf.alert and conf.alert.enable) and "已开启" or "未开启"},
    }
    return {
        content = layui.table(nil, tbl, nil, {'width="150"'}),
    }
end
