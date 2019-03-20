# 可靠消息
rmsg {
    mid number      # 消息唯一标识
    op number       # 消息类型，定义在opcode.lua
    args string     # 消息参数(json格式)
    time number     # 时间戳
    err number      # 执行结果，-1为等待执行，大于等于0为返回错误码
}
