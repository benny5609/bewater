local skynet    = require "skynet"
local layui     = require "bw.cms.layui"

local action = layui.action

return function()
    local item_list = {
        layui.label("地址", 'layui-form-label')..layui.div(layui.input("", "layui-input", {id = "addr"}), 'layui-input-block'),
        layui.label("代码", 'layui-form-label')..layui.div(layui.textarea("", "layui-textarea", {id = "code"}), 'layui-input-block'),
        layui.label("输出", 'layui-form-label')..layui.div(layui.textarea("", "layui-textarea", {id = "output"}), 'layui-input-block'),
        layui.div(layui.button("立即运行", nil, {id = "run"})..layui.button("重置", nil, {id = "reset"}), 'layui-input-block'),
    }
    local run_action = {action.CLICK, "run", {action.POST, "/cms/debug/inject", {
        {action.GET_VAL, "addr"},
        {action.GET_VAL, "code"},
    }}}
    local reset_action = {"reset", action.CLICK, {
        {action.SET_VAL, "code", ""},
        {action.SET_VAL, "output", ""},
    }}
    return {
        content = layui.div(layui.form(item_list), 'layui-col-xs12 layui-col-sm6 layui-col-md6'),
        actions = {
            run_action,
            reset_action,
        },
    }
end
