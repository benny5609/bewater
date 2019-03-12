local skynet 	= require "skynet"
return function(_, data)
    return skynet.call(".cms", "lua", "req_login", data.account, data.password)
end
