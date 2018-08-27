local skynet = require "skynet"
local mongo = require "db.mongo_helper"
local sign = require "auth.sign"
local lua2xml = require "xml.lua2xml"
local xml2lua = require "xml.xml2lua"
local http = require "web.http_helper"
local conf = require "conf"

local M = {}
function M.create_order(param)
    local uid           = assert(param.uid)
    local appid         = assert(param.appid)
    local mch_id        = assert(param.mch_id)
    local key           = assert(param.key)
    local item_sn       = assert(param.item_sn)
    local item_desc     = assert(param.item_desc)
    local pay_channel   = assert(param.pay_channel)
    local pay_method    = assert(param.pay_method)
    local pay_price     = assert(param.pay_price)

    local order_no = string.format("%d%04d", uid, item_sn)
    local order = mongo.find_one("payment", {order_no = order_no})
    if order then
        return order
    end

    local args = {
        appid           = appid,
        mch_id          = mch_id,
        nonce_str       = math.random(10000)..uid,
        trade_type      = pay_method == "mobile" and "APP" or "NATIVE",
        body            = item_desc,    
        out_trade_no    = order_no..'-'..os.time(),
        total_fee       = pay_price*100//1 >> 0,
        spbill_create_ip= '127.0.0.1',
        notify_url      = string.format("%s:%s/api/wxpay_notify", conf.host, conf.port),
    }
    args.sign = sign.md5_args(args, key)
    local xml = lua2xml.encode("xml", args, true)
    print(xml)
    local ret, resp = http.post("https://api.mch.weixin.qq.com/pay/unifiedorder", xml)
    print(ret, resp)
    local data = xml2lua.decode(resp).xml
    print(data.return_code)
    print(data.return_msg)

    if data.return_code ~= "SUCCESS" and data.return_msg ~= "OK" then
        return errcode.WxorderFail
    end

    order = {
        order_no    = order_no,
        uid         = uid,
        item_sn     = item_sn,
        item_state  = item_state,
        pay_channel = pay_channel,
        pay_method  = pay_method,
        pay_time    = os.time(),
        pay_price   = pay_price,
        tid         = "",
    }
    --mongo.safe_insert("payment", order)
   
    local ret
    if data.trade_type == "APP" then 
        ret = {
            partnerid = mch_id,
            noncestr = data.noncestr,
            package = 'Sign=WXPay',
            prepayid = data.prepayid,
            timestamp = os.time(),
        }
        ret.sign = sign.md5_args(ret)
    else
        ret = {
            code_url = data.code_url
        }
    end
    ret.order_no = order_no
    return ret
end

function M.pay_callback(param)

end
return M
