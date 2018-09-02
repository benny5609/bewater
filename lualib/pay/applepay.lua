local base64 = require "auth.base64"
local http = require "web.http_helper"
local json = require "cjson"
local util = require "util"
local M = {}
function M.verify_receipt(receipt)
    --receipt = base64.decode(receipt)
    local ret, resp = http.post("https://buy.itunes.apple.com/verifyReceipt", receipt)
    resp = json.decode(resp)
    if resp.status ~= 0 then
        ret, resp = http.post("https://sandbox.itunes.apple.com/verifyReceipt", receipt)
    end
    print(resp)
    resp = json.decode(resp)
    if not ret or resp.status ~= 0 then
        return
    end

    local tid = resp.receipt.in_app[1].original_transaction_id
    --local item_sn = resp.receipt.in_app[1].product_id
    local item_sn = 1000
    return tid, item_sn 
end
return M

