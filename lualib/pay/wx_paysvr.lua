local skynet = require "skynet"
local mongo = require "db.mongo_helper"

local M = require "pay.paysvr"
function M:start()
    self:init()
    assert(self.pay_result)
end
function M:create_order(args)
    local clustername   = assert(args.clustername)
    local agent         = assert(args.agent)
    local uid           = assert(args.uid)
    local appid         = assert(args.appid)
    local mch_id        = assert(args.mch_id)
    local key           = assert(args.key)
    local proj_name     = assert(args.proj_name)
    local item_sn       = assert(args.item_sn)
    local pay_channel   = assert(args.pay_channel)
    local pay_method    = assert(args.pay_method)
    local pay_price     = assert(args.pay_price)

    local order_no = string.format("%d%04d", uid, sn)
    local order = mongo.find_one("payment", {order_no = order_no})
    if order then
        return order
    end

    local xml = ""

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
    mongo.safe_insert("payment", order)

end

function M:pay_callback()

end
return M
