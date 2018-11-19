local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local json          = require "cjson"
local util          = require "util"
local conf          = require "conf"
local whitelist     = require "ip.whitelist"
local blacklist     = require "ip.blacklist"
local hotfix        = require "hotfix"
local errcode       = require "def.errcode"

local table = table
local string = string

local mode, server_path, handler_path, port, preload, gate = ...
local port = tonumber(port)
local preload = preload and tonumber(preload) or 20

local function response(fd, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", fd, err))
    end
end

if mode == "agent" then
local handler = require(handler_path)

-- handler 需要提供 
-- hander.api = {[[/api/xxx/ooo]] = func} 
-- hander.auth = function(auth) return uid end -- 授权
-- 如果是非字符串，handler需要提供pack和unpack方法
handler.pack = handler.pack or function (_, data)
    return data
end
handler.unpack = handler.unpack or function (_, data)
    return data
end

function on_message(url, args, body, header, ip)
    local auth = header.authorization
    local api = handler.api[url]
    if api then
        local ret, data = util.try(function()
            return handler:unpack(body, url)
        end)
        if not ret then
            return '{"err":2, "desc":"body error"}'
        end
        local ret = 0
        local uid = handler.auth and handler.auth(handler, auth)
        if api.auth and not uid then
            return string.format('{"err":%d}', errcode.AUTH_FAIL)
        end
        if not util.try(function()
            ret = api.cb(handler, args, data, uid, ip, header)
        end) then
        ret = '{"err":3, "desc":"server traceback"}'
        end
        return handler:pack(ret or 0)
    else
        return '{"err":1, "desc":"api not exist"}'
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,fd, ip)
        if fd == "hotfix" then
            handler = hotfix.module(handler_path)
            return
        end
        socket.start(fd)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), nil)
        --util.printdump(header)
        skynet.error(string.format("recv code:%s, url:%s, method:%s, header:%s", code, url, method, header))
        if code then
            if code ~= 200 then
                response(fd, code)
            else
                local data 
                local path, query = urllib.parse(url)
                if query then
                    data = urllib.parse_query(query)
                end
                ip = header['x-real-ip'] or string.match(ip, "[^:]+")
                response(fd, code, on_message(url, data, body, header, ip), {["Access-Control-Allow-Origin"] = "*"})
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(fd)
    end)
    handler:init(gate)
    hotfix.reg()
end)

elseif mode == "gate" then

local server 
if server_path then
    server = require(server_path) 
end

local CMD = {}
function CMD.hotfix()
    server = hotfix.module(server_path)
    return util.NORET
end

skynet.start(function()
    if server then
        server:start()
    end

    local agent = {}
    for i= 1, preload do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent", server_path, handler_path, port, preload, skynet.self())
    end
    local balance = 1
    
    local fd = socket.listen("0.0.0.0", port)
    socket.start(fd , function(fd, ip)
        if conf.whitelist and not whitelist.check(ip) then
            socket.start(fd)
            skynet.error(string.format("not in whitelist:%s", ip))
            response(fd, 403)
            socket.close(fd)
            return
        end
        if conf.blacklist and blacklist.check(ip) then
            socket.start(fd)
            skynet.error(string.format("in blacklist:%s", ip))
            response(fd, 403)
            socket.close(fd)
            return
        end
        --skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", fd, ip)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)

    skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
        local f = assert(CMD[cmd] or server[cmd], cmd)
        if type(f) == "function" then
            util.ret(f(server, subcmd, ...))
        else
            util.ret(f[subcmd](f, ...))
        end
    end)

    hotfix.reg()
end)

else
    assert(false, "mode error")
end
