local bewater = require "bewater"
local layui = require "cms.layui"
local util = require "util"
return function(_, data)
    print("debug inject!", data.addr, data.code)
    local ok, output = bewater.inject(data.addr, data.code)
    print("ret", ok, output)
    return {
        cb = {"output", layui.action.SET_VAL, output}
    }
end
