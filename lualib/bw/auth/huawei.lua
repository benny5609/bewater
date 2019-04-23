local json = require "cjson.safe"
local codec = require "codec"
local http = require "bw.web.http_helper"
local sign = require "bw.auth.sign"
local sha256 = require "bw.auth.sha256"
local log  = require "bw.log"

local table_insert  = table.insert
local table_sort    = table.sort
local table_concat  = table.concat

local API = 'https://gss-cn.game.hicloud.com/gameservice/api/gbClientApi'

local function encode_uri(s)
    assert(s)
    s = string.gsub(s, "([^A-Za-z0-9])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return s
end

local M = {}
function M.gen_token(params, private_key)
    local method = 'methodexternal.hms.gs.checkPlayerSign'
    local args = {
        method      = 'external.hms.gs.checkPlayerSign',
        appId       = encode_uri(params.app_id),
        cpId        = encode_uri(params.cp_id),
        ts          = encode_uri(params.ts),
        playerId    = encode_uri(params.player_id),
        playerLevel = encode_uri(params.player_level),
        playerSSign = encode_uri(params.player_ssign),
    }
    local data = sign.concat_args(args)
    local sign_str = codec.rsa_sha256_private_sign(data, private_key)
    sign_str = codec.base64_encode(sign_str)
    sign_str = encode_uri(sign_str)
    local ret, resp_str = http.post(API, 'cpSign='..sign_str)
    if not ret then
        log.error('cannot request huawei api')
        return
    end
    local resp = json.decode(resp_str)
    if not resp or not resp.rtnSign then
        log.error('huawei api decode error, resp:'..resp_str)
        return
    end
    return resp.rtnSign
end

function M.notify()

end

return M
