local skynet    = require "skynet"
local http      = require "bw.web.http_helper"
local wc        = require "bw.cms.webconsole"
local sname     = require "bw.sname"
local json      = require "cjson.safe"

local function test(filename)
    require("test."..filename)()
end

skynet.start(function()
    --[[wc.init({
        port = "9999",
        users = {
            {account = "root", password = "123"}
        }
    }) ]]
    skynet.error("Be water my friend.")
    --test "test_hall"
end)
