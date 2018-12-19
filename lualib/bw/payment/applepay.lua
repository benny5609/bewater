local json = require "cjson.safe"
local http = require "bw.web.http_helper"

local M = {}
function M.verify_receipt(receipt, product_id)
    --receipt = base64.decode(receipt)
    local ret, resp = http.post("https://buy.itunes.apple.com/verifyReceipt", receipt)
    resp = json.decode(resp)
    if resp.status ~= 0 then
        ret, resp = http.post("https://sandbox.itunes.apple.com/verifyReceipt", receipt)
    end
    resp = json.decode(resp)
    if not ret or not resp or resp.status ~= 0 then
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
end
return M

