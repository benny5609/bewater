local base64 = require "auth.base64"
local http = require "web.http_helper"
local json = require "cjson"
local M = {}
function M.verify_receipt(receipt)
    receipt = base64.decode(receipt)
    local ret, resp = http.post("https://buy.itunes.apple.com/verifyReceipt", receipt)
    resp = json.decode(resp)
    if resp.status ~= 0 then
        ret, resp = http.post("https://sandbox.itunes.apple.com/verifyReceipt", receipt)
    end
    resp = json.decode(resp)
    if not ret or resp.status ~= 0 then
        return
    end

    local tid = resp.in_app.original_transaction_id
    local item_sn = resp.in_app.product_id
    return tid, item_sn 
end
return M

