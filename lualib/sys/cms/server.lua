local skynet    = require "skynet"
local errcode   = require "def.errcode"
local uuid      = require "bw.uuid"
local log       = require "bw.log"

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

function M.req_menu(account)
    local info = acc2info[account]
    if not info then
        return errcode.ACC_NOT_EXIST
    end
    local top = {}
    local navs = {}
    for _, v in ipairs(menu) do
        if not v.lv or info.lv >= v.lv then
            table.insert(top, v)
            navs[v.name] = {}
            for _, vv in ipairs(v.children) do
                if not vv.lv or info.lv >= vv.lv then
                    table.insert(navs[v.name], vv)
                end
            end
        end
    end
    return {
        top = top,
        navs = navs,
    }
end
return M
