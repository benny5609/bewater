local skynet    = require "skynet"
local errcode   = require "def.errcode"
local uuid      = require "bw.uuid"
local log       = require "bw.log"
local util      = require "bw.util"

local trace = log.trace("cms")

local M = {}
local menu = {}
local acc2info = {}
local auth2acc = {}
function M.start(users)
    for _, v in pairs(users) do
        acc2info[v.account] = v
    end

    skynet.register "cms"
end

function M.set_menu(data)
    menu = data
end

function M.get_account(auth)
    return auth2acc[auth]
end

function M.create_auth(account)
    local auth = string.gsub(uuid(), '-', '')
    if auth2acc[auth] then
        return M.create_auth(account)
    end
    auth2acc[auth] = account
    return auth
end

function M.req_login(account, password)
    trace("req_login, account:%s, password:%s", account, password)
    local info = acc2info[account]
    if not info then
        return errcode.ACC_NOT_EXIST
    end
    if password ~= info.password then
        return errcode.PASSWD_ERROR
    end
    return {
        authorization = M.create_auth(account)
    }
end

function M.req_menu()
    return menu
end
return M
