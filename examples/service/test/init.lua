local skynet = require "skynet"
local http   = require "bw.http"
local log    = require "bw.log"
local json   = require "cjson.safe"

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
    log.info("Be water my friend.")
    --test "lfs"
    --test "bash"
end)
