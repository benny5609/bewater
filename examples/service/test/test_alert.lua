local skynet  = require "skynet"
local bewater = require "bw.bewater"
local alert   = require "bw.server.alert"
return function()
    bewater.start(alert, {
        corpid     = '',
        corpsecret = '',
        agentid    = '',
        proj       = 'test',
        desc       = '测试服',

    })
    error("test")
end
