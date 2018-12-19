local skynet = require "skynet"

return function ()
    local menu = skynet.call("cms", "lua", "req_menu")
    local top = {}
    local navs = {}
    for _, v in pairs(menu) do
        table.insert(top, v)
        navs[v.name] = v.children
    end
    return {
        top = top,
        navs = navs,
    }
end
