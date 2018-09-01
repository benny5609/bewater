local skynet = require "skynet"
local mongo = require "db.mongo_helper"
local mysql = require "db.mysql_helper"
local http = require "web.http_helper"
local conf = require "conf"
local util = require "util"
local sign = require "auth.sign"
local codec = require "codec"

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local uid           = assert(param.uid)
    local partner       = assert(param.partner)
    local private_key   = assert(param.private_key)
    local item_sn       = assert(param.item_sn)
    local item_desc     = assert(param.item_desc)
    local pay_channel   = assert(param.pay_channel)
    local pay_method    = assert(param.pay_method)
    local pay_price     = assert(param.pay_price)
    
    local args = {
        partner = partner,
        seller_id = partner,
        out_trade_no = order_no..'-'..os.time(),
        --out_trade_no = "11241000-1535641016", 
        subject = item_desc,
        body = item_desc,
        total_fee = pay_price,
        notify_url = string.format("%s:%s/api/alipay_notify", conf.pay.host, conf.pay.port),
        service = "mobile.securitypay.pay",
        payment_type = '1',
        anti_phishing_key = '',
        exter_invoke_ip = '',
        _input_charset = 'utf-8',
        it_b_pay = '30m',
        return_url = 'm.alipay.com',
    }
    args.sign = sign.rsa_private_sign(args, private_key, true)
    args.sign_type = "RSA"
    return {
        order_no = order_no,
        order = sign.concat_args(args, true),
    }
end

function M.notify(partner, public_key, param)
    if param.trade_status ~= "TRADE_SUCCESS" then
        return
    end
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" and k ~= "sign_type" then
            args[k] = v
        end
    end

    local src = sign.concat_args(args)
    --local bs = param.sign
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    print("src", src)
    print("bs", bs)
    print("pem", pem)
    local ret = codec.rsa_public_verify(src, bs, pem, 2)
    print("verify", ret)

end

return M
