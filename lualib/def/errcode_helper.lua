-- 错误码规范
-- 0x0000 ~ 0x0fff 通用错误码
-- 0x1000 ~ 0xffff 项目自定错误码

local errcode = {}                                                                                                                                                                                                                       
local code2describe = {}
local name2errcode = {}

local function REG(err_name, code, describe)
    assert(not code2describe[code], string.format("errcode 0x%x exist", code))
    name2errcode[err_name] = code
    code2describe[code] = string.format("%s", describe)
end
errcode.REG = REG

function errcode.describe(code)
    return code2describe[code]
end

function errcode.get_name2errcode()
    return name2errcode
end

setmetatable(errcode, {__index = function (_, name)
    return assert(name2errcode[name], name)
end})

REG("OK",                   0x0000, "执行成功")
REG("TRACEBACK",            0x0001, "服务器报错!")
REG("TODO",                 0x0002, "功能开发中")
REG("ARGS_ERROR",           0x0003, "参数错误")
REG("AUTH_FAIL",            0x0004, "验证错误!")
REG("OFFLINE",              0x0005, "已下线")
REG("PROP_ERROR",           0x0006, "配置表错误")
REG("RECONNECTED",          0x0007, "重连成功")
REG("RELOGIN",              0x0008, "重登成功")
REG("KICK",                 0x0009, "在别处登陆")
REG("SERVER_STOP",          0x000a, "服务器维护中")
REG("VERSION_TOO_LOW",      0x000b, "版本更新中")
REG("ACTIVITY_NOT_OPEN",    0x000c, "活动未开放")
REG("REPEAT",               0x000d, "重复操作")
REG("SIGN_ERROR",           0x000e, "签名错误")
REG("SERVER_BUSY",          0x000f, "服务器忙！")
REG("SERVER_CLOSED",        0x0010, "服役器未启动！")

return errcode
