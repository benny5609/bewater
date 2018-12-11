local skynet = require "skynet"
local layui = require "cms.layui"
return function()
    local tbl = {
        {"aaa1", "bb"},
        {"aaa2", "bb"},
        {"aaa3", "bb"},
    }
    return {
        content = layui.table(nil, tbl),
    }
end
