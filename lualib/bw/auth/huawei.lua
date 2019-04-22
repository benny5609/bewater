local http = require "bw.web.http_helper"
local sign = require "bw.auth.sign"
local json = require "cjson.safe"
local log  = require "log"

local table_insert  = table.insert
local table_sort    = table.sort
local table_concat  = table.concat

local API = 'https://gss-cn.game.hicloud.com/gameservice/api/gbClientApi'

local M = {}
function M.gen_token(params, private_key)
    local method = 'methodexternal.hms.gs.checkPlayerSign'
    local data = {
        method      = 'external.hms.gs.checkPlayerSign',
        appId       = assert(params.app_id),
        cpId        = assert(params.cp_id),
        ts          = assert(params.ts),
        playerId    = assert(params.player_id),
        playerLevel = assert(params.player_level),
        playerSSign = assert(params.player_ssign),
    }
    local sign_str = sign.rsa_private_sign(data, private_key, true)
    local ret, resp_str = http.post(API, 'cpSign='..sign_str)
    if not ret then
        log.error('cannot request huawei api')
        return
    end
    local resp = json.decode(resp_str)
    if not resp or not resp.rtnSign then
        log.error('huawei api decode error, resp:%s', resp_str)
        return
    end
    return resp.rtnSign
end

function M.notify()

end

return M
