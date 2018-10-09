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

setmetatable(errcode, {__index = function (_, name)
    return assert(name2errcode[name], name)
end})

REG("OK",                   0x0000, "执行成功")
REG("TRACEBACK",            0x0001, "服务器报错！")
REG("AUTH_FAIL",            0x0002, "验证错误!")
REG("SIGN_ERROR",           0x0003, "签名错误")
REG("SERVER_BUSY",          0x0004, "服务器忙！")
REG("SERVER_CLOSED",        0x0005, "服役器未启动！")

return errcode
