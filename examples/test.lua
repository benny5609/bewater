local skynet    = require "skynet"
local http      = require "web.http_helper"
local wc        = require "cms.webconsole"

skynet.start(function()
    wc.init({
        port = "9999",
    }) 

    local ret, resp = http.post("huangjx.top:9999/api/user/login", {
        account = "root",
        password = "123",
    })
    print(resp)
end)
