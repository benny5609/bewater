local skynet = require "skynet.manager"

local web

local M = {}
function M.init(args)
    local port = assert(args.port)
    local users = assert(args.users)
    web = skynet.newservice("web/webserver", "gate", "cms.server", "cms.handler", port, 10)
    skynet.call(web, "lua", "start", users)

    skynet.call(web, "lua", "insert_left_menu", {
        text = "Skynet", children = {
            {text = "节点信息", view = "view/node_info"},
            {text = "所有服务", view = "view/all_service"},
            {text = "注入调试", view = "view/inject"},
            {text = "GM", view = "view/gm"},
        }
    })
end

function M.add_api(path)
    assert(web, "webconsole not init")
    skynet.call(web, "lua", "add_api", path)
end

return M
