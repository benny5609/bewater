local skynet = require "skynet"
local json = require "cjson.safe"

local M = {
    root = "cms",
    api = {
        ['/api/user/login'] = {args = {account = "STR", password = "STR"}, auth = false},
    },
}

function M.pack(data)
    return json.encode(data)
end

function M.unpack(data)
    return json.decode(data)
end

function M:auth(p)
    local addr = skynet.uniqueservice("passport")
    return skynet.call(addr, "lua", "get_uid", p)
end

return M
