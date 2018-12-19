local skynet    = require "skynet"
local http      = require "bw.web.http_helper"
local wc        = require "bw.cms.webconsole"
local json      = require "cjson.safe"

skynet.start(function()
    wc.init({
        port = "9999",
        users = {
            {account = "root", password = "123"}
        }
    }) 
    
    print "Be water my friend."

end)
