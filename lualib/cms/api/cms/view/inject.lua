local skynet = require "skynet"
local layui = require "cms.layui"

return function()
    local item_list = {
        layui.label("地址")..layui.input(),
        layui.label("地址")..layui.input(),
        layui.label("地址")..layui.input(),
    }
    return {
        content = layui.form(item_list)
    }
end
