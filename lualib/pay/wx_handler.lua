local skynet = require "skynet"
local util = require "util"

local M = {}
function M:init(gate)
    self.gate = gate
end

function M:wxpay_notify(args, body, ip)
    print("on pay", args, body, ip)
end
return M
