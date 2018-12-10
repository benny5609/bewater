local skynet = require "skynet.manager"

local web

local M = {}
function M.init(args)
    local port = assert(args.port)
    local users = assert(args.users)
    web = skynet.newservice("web/webserver", "gate", "cms.server", "cms.handler", port, 10)
    skynet.call(web, "lua", "start", users)

    skynet.call(web, "lua", "set_menu", {
        {name = "skynet", title = "Skynet", icon = "&#xe665;", children = {
            {title = "节点信息", href = "/cms/view/node_info"},
            {title = "所有服务", href = "/cms/view/all_service"},
            {title = "注入调试", href = "/cms/view/inject"},
            {title = "GM", href = "/cms/view/gm"},
        }},
        {name = "user", title = "用户管理", icon = "&#xe665;", children = {
            {title = "数据统计", href = "/cms/view/node_info", icon = "&#xe665;"},
            {title = "GM", href = "/cms/view/gm"},
        }},
        {name = "update", title = "更新", icon = "&#xe665;", children = {
            {title = "客户端更新", href = "/cms/view/node_info"},
            {title = "服务端热更", href = "/cms/view/gm"},
        }},
    })
end

function M.add_api(path)
    assert(web, "webconsole not init")
    skynet.call(web, "lua", "add_api", path)
end

return M
