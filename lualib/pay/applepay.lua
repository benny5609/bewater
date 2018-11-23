--local base64 = require "auth.base64"
local Http = require "web.http_helper"
local Json = require "cjson"
local M = {}
function M.verify_receipt(receipt, product_id)
    --receipt = base64.decode(receipt)
    local ret, resp = Http.post("https://buy.itunes.apple.com/verifyReceipt", receipt)
    resp = Json.decode(resp)
    if resp.status ~= 0 then
        ret, resp = Http.post("https://sandbox.itunes.apple.com/verifyReceipt", receipt)
    end
    resp = Json.decode(resp)
    if not ret or resp.status ~= 0 then
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

