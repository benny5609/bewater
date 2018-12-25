local skynet        = require "skynet"
local layui         = require "bw.cms.layui"
local date_helper   = require "bw.util.date_helper"
local node_info     = require "bw.cms.api.cms.view.node_info"

local action = layui.action

return function()
    local html = layui.blockquote("节点信息")
    html = html ..  node_info().content

    local online = 0
    local run_time = date_helper.format_now()
    return {
        content = html,
        actions = {
            {action.SET_TEXT, "online", online},
            {action.SET_TEXT, "online", run_time},
        }
    }
end
