--  微信验证
--  每个需要用到的服务都需要在启动的时候调wx.init
--

local skynet    = require "skynet"
local http      = require "web.http_helper"
local json      = require "cjson"
local sha256    = require "auth.sha256"
local datacenter= require "skynet.datacenter"

local access_token      = ''
local access_exires_in  = 0
local access_time       = 0 

local map = {} -- appid -> access

local function request_access_token(appid, secret)
    assert(appid and secret)
    local ret, resp = http.get("https://api.weixin.qq.com/cgi-bin/token", {
        grant_type  = "client_credential",
        appid       = appid,
        secret      = secret,
    }) 
    if ret then
        resp = json.decode(resp)
        local access = {}
        access.token       = resp.access_token
        access.exires_in   = resp.expires_in
        access.time        = os.time()
        map[appid] = access
    else
        error(resp)
    end
end

local M = {}
function M.get_access_token(appid, secret)
    assert(appid and secret)
    local access = map[appid]
    if not access or  os.time() - access.time > access.exires_in then
        request_access_token(appid, secret)
        return map[appid]
    end
    return access.token
end

function M:check_code(appid, secret, js_code)
    assert(appid and secret and js_code)
    local ret, resp = http.get("https://api.weixin.qq.com/sns/jscode2session",{
        js_code = js_code,
        grant_type = "authorization_code",
        appid = appid,
        secret = secret,
    })
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- data {score = 100, gold = 300}
function M:set_user_storage(appid, secret, openid, session_key, data)
    local kv_list = {}
    for k, v in pairs(data) do
        table.insert(kv_list, {key = k, value = v})
    end
    local post = json.encode({kv_list = kv_list})
    local url = "https://api.weixin.qq.com/wxa/set_user_storage?"..http.url_encoding({
        access_token = M.get_access_token(appid, secret),
        openid = openid,
        appid = appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256", 
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- key_list {"score", "gold"}
function M:remove_user_storage(appid, secret, openid, session_key, key_list)
    local post = json.encode({key = key_list})
    local url = "https://api.weixin.qq.com/wxa/remove_user_storage?"..http.url_encoding({
        access_token = M.get_access_token(appid, secret),
        openid = openid,
        appid = appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256", 
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

return M
