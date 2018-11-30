local Sign      = require "auth.sign"
local Lua2xml   = require "xml.lua2xml"
local Xml2lua   = require "xml.xml2lua"
local Http      = require "web.http_helper"
local Conf      = require "conf"
local Errcode   = require "def.errcode"
local Def       = require "def"
local Util      = require "util"
local Log       = require "log"
local trace     = Log.trace("wxpay")

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local uid           = assert(param.uid)
    local appid         = assert(param.appid)
    local mch_id        = assert(param.mch_id)
    local key           = assert(param.key)
    local item_desc     = assert(param.item_desc)
    local pay_method    = assert(param.pay_method)
    local pay_price     = assert(param.pay_price)
    assert(param.pay_channel)
    assert(param.item_sn)

    local args = {
        appid           = appid,
        mch_id          = mch_id,
        nonce_str       = math.random(10000)..uid,
        trade_type      = pay_method == "wxpay" and "APP" or "NATIVE",
        body            = item_desc,
        out_trade_no    = order_no..'-'..os.time(),
        total_fee       = pay_price*100//1 >> 0,
        spbill_create_ip= '127.0.0.1',
        notify_url      = string.format("%s:%s/api/payment/wxpay_notify", Conf.pay.host, Conf.pay.port),
    }
    args.sign = Sign.md5_args(args, key)
    local xml = Lua2xml.encode("xml", args, true)
    local _, resp = Http.post("https://api.mch.weixin.qq.com/pay/unifiedorder", xml)
    local data = Xml2lua.decode(resp).xml

    if data.return_code ~= "SUCCESS" and data.return_msg ~= "OK" then
        return Errcode.WXORDER_FAIL
    end

    local ret
    if data.trade_type == "APP" then
        ret = {
            appid = appid,
            partnerid = mch_id,
            noncestr = data.nonce_str,
            package = 'Sign=WXPay',
            prepayid = data.prepay_id,
            timestamp = os.time(),
        }
        ret.sign = Sign.md5_args(ret, key)
    else
        ret = {
            code_url = data.code_url
        }
    end
    ret.order_no = order_no
    return ret
end

local WX_OK = {
    return_code = "SUCCESS",
    return_msg  = "OK",
}

local WX_FAIL = {
    return_code = "FAIL",
    return_msg  = "FAIL",
}

function M.notify(order, key, param)
    if order.item_state == Def.PayState.SUCCESS then
        return WX_OK
    end
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" then
            args[k] = v
        end
    end

    local sign1 = Sign.md5_args(args, key)
    local sign2 = param.sign
    if sign1 ~= sign2 then
        return WX_FAIL
    end

    if param.result_code ~= "SUCCESS" or param.return_code ~= "SUCCESS" then
        trace("wxpay fail %s", Util.dump(param))
    else
        order.pay_time = os.time()
        order.tid = param.transaction_id
    end
    return WX_OK
end
return M
