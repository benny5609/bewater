local skynet = require "skynet"
local layui = require "cms.layui"
local action = layui.action
return function()
    local item_list = {
        layui.label("指令", 'layui-form-label')..layui.div(layui.input("", "layui-input", {id = "gm", autocomplete = "on"}), 'layui-input-block'),
        layui.label("输出", 'layui-form-label')..layui.div(layui.textarea("", "layui-textarea", {id = "output", style = "height:600px"}), 'layui-input-block'),
        layui.div(layui.button("立即运行", nil, {id = "run"})..layui.button("重置", "layui-btn-primary", {id = "reset"}), 'layui-input-block'),
    }
    local run_action = {"run", action.POST, "/cms/user/gm", {
        {"gm", action.GET_VAL},
    }}
    local reset_action = {"reset", action.CLICK, {
        {"output", action.SET_VAL, ""},
    }}
    return {
        content = layui.div(layui.form(item_list), 'layui-col-xs12 layui-col-sm12 layui-col-md11'),
        actions = {
            run_action,
            reset_action,
        },
    }
end
