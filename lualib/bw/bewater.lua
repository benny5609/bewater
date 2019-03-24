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

function M.reg_code(env)
    local code = require "bw.proto.code"
    code.REG(env)
end

-- 给一个服务注入一段代码
-- return ok, output
function M.inject(addr, source)
    return skynet.call(addr, "debug", "RUN", source)
    --return skynet.call(addr, "code", source)
    --return skynet.call(addr, "debug", "INJECTCODE", source, filename)
    --local injectcode = require "skynet.injectcode"
    --return injectcode(source)
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

function M.locals(f)
    f = f or 2
    local variables = {}
    local idx = 1
    while true do
        local ln, lv = debug.getlocal(f, idx)
        if ln ~= nil then
            variables[ln] = lv
        else
            break
        end
        idx = 1 + idx
    end
    return variables
end

function M.traceback(start_level, max_level)
    start_level = start_level or 2
    max_level = max_level or 20

    for level = start_level, max_level do

        local info = debug.getinfo( level, "nSl")
        if info == nil then break end
        print( string.format("[ line : %-4d]  %-20s :: %s",
            info.currentline, info.name or "", info.source or "" ) )

        local index = 1
        while true do
            local name, value = debug.getlocal(level, index)
            if name == nil then break end
            print( string.format( "\t%s = %s", name, value ) )
            index = index + 1
        end
    end
end

function M.protect(tbl, depth)
    setmetatable(tbl, {
        __index = function(t, k)
            local v = rawget(t, k)
            assert(v ~= nil, string.format("read error key:%s", k))
            return v
        end,
        __newindex = function(t, k, v)
            assert(rawget(t, k) ~= nil, string.format("write error key:%s", k))
            rawset(t, k, v)
        end
    })
    if depth and depth > 0 then
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                M.protect(v, depth - 1)
            end
        end
    end
    return tbl
end

function M.proxy(addr, is_send)
    assert(addr)
    return setmetatable({}, {
        __index = function(_, k)
            return function(...)
                if is_send then
                    return skynet.send(addr, "lua", ...)
                else
                    skynet.call(addr, "lua", ...)
                end
            end
        end,
    })
end

function M.start(handler, start_func)
    assert(handler)
    assert(start_func)
    skynet.start(function()
        skynet.dispatch("lua", function(_,_, cmd, ...)
            local f = assert(handler[cmd], cmd)
            M.ret(f(...))
        end)
        start_func()
    end)
end

return M

