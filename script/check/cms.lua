local skynet    = require "skynet"
local json      = require "cjson.safe"
local http      = require "bw.web.http_helper"
local wc        = require "bw.cms.webconsole"
local errcode   = require "def.errcode"

local authorization
local host = "127.0.0.1:9999"

local function check_login(account, password, expect_err)
    local ret, resp = http.post(host.."/cms/user/login", json.encode {
        account = account,
        password = password,
    })
    resp = assert(json.decode(resp), resp)
    assert(ret)
    assert(resp.err == (expect_err or 0), errcode.describe(resp.err))
    return resp
end

local function check_api(api, param, expect_err)
    local ret, resp = http.post(host..api, json.encode(param), {authorization = authorization})
    resp = assert(json.decode(resp), resp)
    assert(ret)
    assert(resp.err == (expect_err or 0), errcode.describe(resp.err))
    return resp  
end

return function()
    wc.init({
        port = "9999",
        users = {
            {account = "root", password = "123"}
        }
    }) 
    check_api("/cms/view/menu", {}, errcode.AUTH_FAIL)

    check_login("aaa", "2222", errcode.ACC_NOT_EXIST)   
    check_login("root", "xxx", errcode.PASSWD_ERROR)

    local ret = check_login("root", "123")
    authorization = assert(ret.authorization)
    check_api("/cms/view/menu", {})
    html = check_api("/cms/view/all_service", {})
    --print(html.content)
    html = check_api("/cms/view/inject", {})
    --print(html.content)
    
    check_api("/cms/user/gm", {}, errcode.ARGS_ERROR)
    return true
end

