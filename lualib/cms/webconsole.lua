local skynet = require "skynet"

local web

local M = {}
function M.init(args)
    web = skynet.newservice("web/webserver", "gate", "cms.server", "cms.handler",
        args.port, 10)
end
function M.add_api(path)
    assert(web, "webconsole not init")
    skynet.call(web, "lua", "add_api", path)
end
return M
