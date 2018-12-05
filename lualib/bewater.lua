local skynet = require "skynet.manager"

local M = {}
M.NORET = "NORET"
function M.ret(noret, ...)
    if noret ~= M.NORET then
        skynet.retpack(noret, ...)
    end
end

local function __TRACEBACK__(errmsg)
    local track_text = debug.traceback(tostring(errmsg), 2)
    skynet.error("---------------------------------------- TRACKBACK ----------------------------------------")
    skynet.error(track_text, "LUA ERROR")
    skynet.error("---------------------------------------- TRACKBACK ----------------------------------------")
    return false
end

-- 尝试调一个function, 如果被调用的函数有异常,返回false，
function M.try(func, ...)
    return xpcall(func, __TRACEBACK__, ...)
end

-- 给一个服务注入一段代码
-- return ok, output
function M.inject(addr, source, filename)
    return skynet.call(addr, "debug", "RUN", source, filename)
end

function M.timeout_call(ti, ...)
    local co = coroutine.running()
    local ret

    skynet.fork(function(...)
        ret = table.pack(pcall(skynet.call, ...))
        if co then
            skynet.wakeup(co)
            co = nil
        end
    end, ...)

    skynet.sleep(ti/10)

    if co then
        co = nil
        skynet.error("call timeout:", ...)
        return false
    else
        if ret[1] then
            return table.unpack(ret, 1, ret.n)
        else
            error(ret[2])
        end
    end
end

return M

