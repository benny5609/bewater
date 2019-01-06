local skynet = require "skynet"
local conf = {
    workspace = skynet.getenv('workspace'),
    clustername = skynet.getenv('clustername'),
    debug = true,

    proj = "test",
    desc = "测试服",

    mongo = {
        host = "127.0.0.1",
        name = "test",
        port = 27017,
    },

    alert = {
        enable      = true,
        corpid      = '',
        corpsecret  = '',
        agentid     = '',
    },
}

return conf
