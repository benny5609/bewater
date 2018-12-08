local skynet = require "skynet"
local errcode = require "def.errcode"
local uuid = require "uuid"
local log = require "log"
local util = require "util"

local trace = log.trace("cms")

local M = {}
local menu = {
    left = {},  -- 左侧菜单
    top = {},   -- 顶部菜单
}
local acc2info = {}
local auth2acc = {}
function M.start(users)
    for _, v in pairs(users) do
        acc2info[v.account] = v
    end

    skynet.register "cms"
end

function M.add_menu(side, new, ...)
    local item_list = assert(menu[side], side)
    local idx_list = {...}
    if #idx_list == 0 then
        table.insert(item_list, new)
    else
        local cur = item_list
        for _, idx in ipairs(idx_list) do
            cur = cur[idx] 
        end
        table.insert(cur, new)
    end
end

function M.insert_left_menu(menu, ...)
    M.add_menu("left", menu, ...)
end

function M.insert_top_menu(menu, ...)
    M.add_menu("top", menu, ...)
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
    util.printdump(menu)
    return menu
end
return M
