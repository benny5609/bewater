local skynet = require "skynet"
return function ()
    return skynet.call("cms", "lua", "req_menu")
end
