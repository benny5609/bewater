local skynet     = require "skynet"
local gateserver = require "bw.server.http_gate"
local server     = require "sys.cms.server"

server.start({
    {
        account = "root",
        password = "123",
        auth = "admin",
        name = '战斗鸡',
        avatar = 'https://avatars0.githubusercontent.com/u/41313881?s=460&v=4',
        userid = '00000001',
        email = 'zhandouxiaojiji@gmail.com',
        signature = '',
        title = '交互专家',
        group = '蚂蚁金服－某某某事业群－某某平台部－某某技术部－UED',
        tags = {},
        notifyCount = 12,
        unreadCount = 66,
        country = 'China',
        geographic = {},
        address = '西湖区工专路 77 号',
        phone = '0752-268888888',
    },
    {account = "guest", password = "123", auth = "guest"},
    {account = "user", password = "123", auth = "user"},
})

gateserver.start(server, "cms/agent", 9999)

skynet.register ".cms"
