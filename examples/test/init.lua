local skynet    = require "skynet"
local http      = require "bw.web.http_helper"
local wc        = require "bw.cms.webconsole"
local json      = require "cjson.safe"

local function test(name)
    require("test_"..name)()
end

skynet.start(function()
    --[[wc.init({
        port = "9999",
        users = {
            {account = "root", password = "123"}
        }
    }) ]]
    skynet.error("Be water my friend.")
    --test "huawei"
    test "http"
end)
