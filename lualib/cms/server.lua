local skynet = require "skynet"
local errcode = require "errcode"

local M = {}
local acc2info = {}
function M.start(users)
    for _, v in pairs(users) do
        acc2info[v.account] = v
    end

    skynet.register "webconsole"
end

function M.req_login(account, password)
    local info = acc2info[account]
    if not info then
        return errcode.ACC_NOT_EXIST
    end
    if password ~= info.password then
        return errcode.PASSWD_ERROR
    end
    local addr = skynet.uniqueservice("passport")
    return {
        authorization = skynet.call(addr, "lua", "create", account)
    }
end
return M
