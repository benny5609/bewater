local skynet = require "skynet"
package.path = "?.lua;" .. package.path

local _ENV = setmetatable({}, {__index = _ENV})

local function io_popen(cmd, mode)
    local file = io.popen(cmd)
    local ret = file:read(mode or "*a")
    file:close()
    return ret
end

function add_lua_search_path(path)
    if not string.find(package.path, path, 1, true) then
        print("add search path: " .. path)
        package.path = path .. "/?.lua;" .. package.path
    end
end

function command(cmd, ...)
    local data = io_popen(string.format(cmd, ...))
    return string.match(data, "(.*)[\n\r]+$") or data
end

function cat(path)
    local file = io.open(path)
    assert(file, "file not found: " .. path)
    local data = file:read("*a")
    file:close()
    return data
end

function exist(path)
    local file = io.open(path)
    if file then
        file:close()
    end
    return file ~= nil
end

function wcat(path)
    return io_popen("lynx -source " .. path)
end

function echo(path, content)
    local file = io.open(path, "w")
    file:write(content)
    file:flush()
    file:close()
end

local function lookup_local(level, key)
    assert(key and #key > 0, key)
    for i = 1, 256 do
        local k, v = debug.getlocal(level, i)
        if k == key then
            return v
        elseif not k then
            break
        end
    end

    local info1 = debug.getinfo(level, 'S')
    local info2 = debug.getinfo(level + 1, 'S')
    if info1.source == info2.source or
        info1.short_src == info2.short_src then
        return lookup_local(level + 1, key)
    end
end

function bash(expr, ...)
    if select('#', ...) > 0 then
        expr = string.format(expr, ...)
    end
    local function eval(expr)
        return string.gsub(expr, "(${?[%w_]+}?)", function (str)
            local key = string.match(str, "[%w_]+")
            local value = lookup_local(6, key) or _G[key]
            if value == nil then
                error("value not found for " .. key)
            else
                return tostring(value)
            end
        end)
    end
    local cmd = eval(expr)
    --skynet.error(cmd)
    local ret = io_popen(cmd)
    if ret ~= "" then
        --skynet.error(ret)
    end
    return ret
end

function remote_bash(user, host, expr, ...)
    local cmd = string.format(expr, ...)
    if host == "localhost" or host == "127.0.0.1" then
        return bash(cmd)
    end
    return bash('ssh %s@%s "%s"', user, host, cmd)
end

function stdout(cmd, filename)
    if not filename then
        local conf   = require "conf"
        filename = conf.workspace.."/log/stdout.log"
    end
    bash('echo "%s" > %s', cmd, filename)
    cmd = string.format('%s >%s 2>&1', cmd, filename)
    local runing = true
    skynet.timeout(0, function()
        local file = io.open(filename, "r")
        local offset = 0
        while true do
            file:seek("set", offset)
            print("&&&&&")
            --print(file:read("a")) 
            offset = file:seek()
            skynet.sleep(10)
            if not runing then
                break
            end
        end
        bash("rm "..filename)
        skynet.error("done")
    end)
    os.execute(cmd)
    runing = false
end

return _ENV
