local skynet = require "skynet"
return function(_, _, account)
    return skynet.call(".cms", "lua", "req_current", account)
end
