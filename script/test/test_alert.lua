local skynet = require "skynet"
local sname = require "bw.sname"
return function()
    --skynet.call(sname.ALERT, "lua", "test", "hello")
    error("test")
end
