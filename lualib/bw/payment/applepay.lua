local json = require "cjson.safe"
local http = require "bw.web.http_helper"
local log  = require "bw.log"

local trace = log.trace("applepay")

local M = {}
function M.verify_receipt(receipt, product_id)
    local ret, resp_str = http.post("https://buy.itunes.apple.com/verifyReceipt", receipt)
    local resp = json.decode(resp_str)
    if not ret then
        log.error("verify_receipt error, post:buy, product_id:%s, receipt:%s",
            product_id, receipt)
        return
    end
    if resp.status ~= 0 then
        trace("try sandbox")
        ret, resp_str = http.post("https://sandbox.itunes.apple.com/verifyReceipt", receipt)
        resp = json.decode(resp_str)
    end
    if not ret or not resp or resp.status ~= 0 then
        log.error("verify_receipt error, ret:%s, resp:%s", ret, resp_str)
        return
    end
    if not product_id then
        return resp.receipt.in_app[1].original_transaction_id
    end
    for i, v in pairs(resp.receipt.in_app) do
        if v.product_id == product_id then
            return v.original_transaction_id
        end
    end
    log.error("verify_receipt error, product_id is wrong, product_id:%s, ret:%s, resp_str:%s",
        product_id, ret, resp_str)
end
return M

