local skynet    = require "skynet"
local json      = require "cjson.safe"
package.path = "../bewater/lualib/sys/cms/?.lua;" .. package.path

require "user.login"

local M = {
    api = {
        ['/cms/user/login'] = {data = {userName = "str", password = "str", type = "str"}, auth = false},
        ['/cms/user/current'] = {auth = true},
        ['/cms/user/gm'] = {data = {gm = "str"}, auth = true},
        ['/cms/user/menu'] = {auth = true},
        ['/cms/debug/inject'] = {auth = true},
        ['/cms/skynet/node_info'] = {auth = true},
        ['/cms/skynet/all_service'] = {auth = true},
        ['/cms/sys/main'] = {auth = true},
    },
}

function M.topath(url)
    return string.sub(url, 6, -1)
end

function M.pack(data)
    return json.encode(data)
end

function M.unpack(data)
    return json.decode(data)
end

function M.auth(authorization)
    return skynet.call(".cms", "lua", "get_account", authorization)
end

return M
