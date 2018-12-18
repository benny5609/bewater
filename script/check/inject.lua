local skynet = require "skynet"
local function inject(source)
    return skynet.call("check", "code", source)
end
return function ()
    inject([[print "hello"]])
    inject([[print(skynet)]])
    inject([[
    local bewater = require "bewater"
    print(bewater.traceback())
    ]])
    inject([[print(check_list)]])
end
