local skynet    = require "skynet"
local json      = require "cjson.safe"
package.path = "../bewater/lualib/bw/cms/api/?.lua;" .. package.path

local M = {
    api = {
        ['/cms/user/login'] = {data = {account = "STR", password = "STR"}, auth = false},
        ['/cms/user/gm'] = {data = {gm = "STR"}, auth = true},
        ['/cms/debug/inject'] = {auth = true},
        ['/cms/skynet/node_info'] = {auth = true},
        ['/cms/skynet/all_service'] = {auth = true},
        ['/cms/sys/main'] = {auth = true},
        ['/cms/view/menu'] = {auth = true},
    },
}

function M.pack(data)
    return json.encode(data)
end

function M.unpack(data)
    return json.decode(data)
end

function M.auth(authorization)
    return skynet.call("cms", "lua", "get_account", authorization)
end

return M
