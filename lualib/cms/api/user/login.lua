local skynet = require "skynet"
local util = require "util"
return function(_, data)
    return skynet.call("webconsole", "lua", "req_login", data.account, data.password)
end
