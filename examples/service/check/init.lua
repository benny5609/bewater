local skynet = require "skynet"
local bewater = require "bw.bewater"

require "bw.util.ip_country"
require "bw.schedule"

local check_list = {
    "check_ip_country",
    "check_schedule",
    "check_cms",
    "check_date_helper",
    "check_logger",
    "check_context",
}


skynet.start(function()
    skynet.register "check"

    local count = 0
    for i, v in ipairs(check_list) do
        local ret = require(v)
        if type(ret) == "function" then
            ret = ret()
        end
        assert(ret, v.." error")
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
