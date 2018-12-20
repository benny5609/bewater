local skynet = require "skynet.manager"

local web

local M = {}
function M.init(args)
    local port = assert(args.port)
    local users = assert(args.users)
    web = skynet.newservice("web/webserver", "gate", args.server or "bw.cms.server",
        args.handler or "bw.cms.handler", port, 10)
    skynet.call(web, "lua", "start", users)

    skynet.call(web, "lua", "set_menu", args.menu or {
        {name = "skynet", title = "Skynet", icon = "&#xe665;", children = {
            {title = "节点信息", icon = "&#xe857", href = "/cms/view/node_info"},
            {title = "所有服务", icon = "&#xe62d;", href = "/cms/view/all_service"},
            {title = "注入调试", icon = "&#xe631;", href = "/cms/view/inject"},
            {title = "GM", icon = "&#xe64e;", href = "/cms/view/gm"},
        }},
        {name = "user", title = "用户管理", icon = "&#xe770;", children = {
            {title = "数据统计", icon = "&#xe62c;", href = "/cms/view/stat", icon = "&#xe665;"},
            {title = "GM", icon = "&#xe64e;", href = "/cms/view/gm"},
        }},
        {name = "update", title = "更新", icon = "&#xe609;", children = {
            {title = "客户端更新", icon = "&#xe62f;", href = "/cms/view/client_update"},
            {title = "服务端热更", icon = "&#xe62f;", href = "/cms/view/server_update"},
        }},
    })
end

return M
