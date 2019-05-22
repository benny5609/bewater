-- 华为支付
local codec = require "codec"
local sign  = require "bw.auth.sign"

local M = {}
function M.create_order(param)
    local private_key   = assert(param.private_key)
    local pay_price     = assert(param.pay_price)
    local url           = assert(param.url)
    assert(param.order_no)
    assert(param.item_sn)
    assert(param.pay_channel)
    assert(param.pay_method)

    local args = {
        productNo = param.item_sn,
        applicationID = param.appid,
        requestId = param.order_no,
        merchantId = param.cpid,
        sdkChannel = '1',
        urlver = '2',
        url = url,
    }
    local str = sign.concat_args(args)
    local bs = codec.rsa_sha256_private_sign(str, private_key)
    str = codec.base64_encode(bs)

    return {
        appid    = param.appid,
        cpid     = param.cpid,
        cp       = param.cp,
        item_sn  = param.item_sn,
        order_no = param.order_no,
        url      = url,
        catalog  = 'X5',
        sign     = str,
    }
end

function M.notify(public_key, param)
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" and k ~= "signType" then
            args[k] = v
        end
    end

    local src = sign.concat_args(args)
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    return codec.rsa_sha256_public_verify(src, bs, pem, 2)
end

return M
