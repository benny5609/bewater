local skynet     = require "skynet"
local gateserver = require "bw.web.gateserver"
local server     = require "sys.cms.server"

server.start({
    {account = "root", password = "123"},
    {account = "guest", password = "123"}
})

gateserver.start(server, "cms/agent", 9999)
