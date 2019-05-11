local skynet = require "skynet"
local workspace = skynet.getenv('workspace')
local conf = {
    workspace = workspace,
    clustername = skynet.getenv('clustername'),
    debug = true,

    proj = "test",
    desc = "测试服",

    mongo = {
        host = "127.0.0.1",
        name = "test",
        port = 27017,
    },

    typedef = workspace.."lualib/def/typedef",

    alert = {
        enable      = false,
        corpid      = '',
        corpsecret  = '',
        agentid     = '',
    },
}

return conf
