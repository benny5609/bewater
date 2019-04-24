-- 华为支付
local conf  = require "conf"
local codec = require "codec"
local sign  = require "bw.auth.sign"

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local private_key   = assert(param.private_key)
    local item_desc     = assert(param.item_desc)
    local pay_price     = assert(param.pay_price)
    local partner       = assert(param.partner)
    assert(param.uid)
    assert(param.item_sn)
    assert(param.pay_channel)
    assert(param.pay_method)

    local url = string.format('%s/api/payment/huawei_notify', conf.pay.host),
    local args = {
        productNo = param.item_sn,
        applicationID = param.appid,
        requestId = param.order_no,
        merchantId = param.cpid,
        sdkChannel = '1',
        urlver = '2',
        url = url,
    }
    local sign = sign.rsa_private_sign(args, private_key, true)
    return {
        appid    = param.appid,
        cpid     = param.cpid,
        cp       = '琢玉教育',
        item_sn  = param.item_sn,
        order_no = param.order_no,
        url      = url,
        catalog  = 'X5',
        sign     = sign,
    }
end

function M.notify(public_key, param)
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" and k ~= "sign_type" then
            args[k] = v
        end
    end

    local src = sign.concat_args(args)
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    return codec.rsa_public_verify(src, bs, pem, 2)
end

return M
