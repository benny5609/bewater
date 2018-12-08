local skynet = require "skynet"

require "ip.ip_country"
require "schedule"

local check_list = {
    "ip_country",
    "schedule",
    "cms",
}
skynet.start(function()
    local count = 0
    for i, v in ipairs(check_list) do
        local ret = require("check."..v)
        if type(ret) == "function" then
            ret = ret()
        end
        skynet.error(string.format("check %s %s", v, ret and "ok" or "fail"))
        if ret then
            count = count + 1
        else
            break
        end
    end
    skynet.error(string.format("check %d files, %d ok, %d fail", 
        #check_list, count, #check_list - count))
end)
