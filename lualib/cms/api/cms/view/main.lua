local skynet        = require "skynet"
local layui         = require "cms.layui"
local node_info     = require "cms.api.cms.view.node_info"
local date_helper   = require "util.date_helper"

local action = layui.action

return function()
    local html = layui.blockquote("节点信息")
    html = html ..  node_info().content

    local online = 0
    local run_time = date_helper.format_now()
    return {
        content = html,
        actions = {
            {"online", action.SET_TEXT, online},
            {"run_time", action.SET_TEXT, run_time},
        }
    }
end
