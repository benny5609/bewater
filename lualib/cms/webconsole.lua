local skynet = require "skynet"

local web

local M = {}
function M.init(args)
    local port = assert(args.port)
    local users = assert(args.users)
    web = skynet.newservice("web/webserver", "gate", "cms.server", "cms.handler", port, 10)
    skynet.call(web, "lua", "start", users)
end
function M.add_api(path)
    assert(web, "webconsole not init")
    skynet.call(web, "lua", "add_api", path)
end
return M
