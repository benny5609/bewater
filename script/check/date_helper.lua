local d = require "util.date_helper"
return function()
    assert(d.format_now(1) == "0分1秒")
    assert(d.format_now(305) == "5分5秒")
    assert(d.format_now(24*3600+1) == "1天0小时")
    assert(d.format_now(24*3600+3660) == "1天1小时")
    assert(d.format_now(29*24*3600+3660) == "29天1小时")
    return true
end
