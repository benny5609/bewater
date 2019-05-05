-- oppo支付
local codec     = require "codec"
local sign      = require "bw.auth.sign"
local http      = require "bw.web.http_helper"
local util      = require "bw.util"
local log       = require "bw.log"
local errcode   = require "def.errcode"
local def       = require "def.def"
local conf      = require "conf"
local trace     = log.trace("oppay")

local CALLBACK_OK = "OK"
local CALLBACK_FAIL = "FAIL"

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local item_desc     = assert(param.item_name)
    local pay_price     = assert(param.pay_price)
    local secret        = assert(param.secret)
    assert(param.pay_channel)
    assert(param.item_sn)

    return {
        order_no    = order_no,
        price       = pay_price,
        name        = item_desc,
        desc        = item_desc,
        url         = string.format("%s:%s/api/payment/opop_notify", conf.pay.host, conf.pay.port),
        attach      = codec.md5_encode(order_no..secret),
    }
end

function M.notify(param, public_key, secret)
    local list = {
        string.format('%s=%s', 'notifyId', param.notifyId),
        string.format('%s=%s', 'partnerOrder', param.partnerOrder),
        string.format('%s=%s', 'productName', param.productName),
        string.format('%s=%s', 'productDesc', param.productDesc),
        string.format('%s=%s', 'price', param.price),
        string.format('%s=%s', 'count', param.count),
        string.format('%s=%s', 'attach', param.attach),
    }
    local src = table.concat(list, "&")
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    return codec.rsa_public_verify(src, bs, pem, 2)

end
return M
