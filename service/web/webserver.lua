local Skynet        = require "skynet"
local Socket        = require "skynet.socket"
local Httpd         = require "http.httpd"
local Sockethelper  = require "http.sockethelper"
local Url           = require "http.url"
local Util          = require "Util"
local Conf          = require "conf"
local Whitelist     = require "ip.whitelist"
local Blacklist     = require "ip.blacklist"
local Hotfix        = require "hotfix"
local errcode       = require "def.errcode"

local mode, server_path, handler_path, port, preload, gate = ...
port = tonumber(port)
preload = preload and tonumber(preload) or 20

local function response(fd, ...)
    local ok, err = Httpd.write_response(Sockethelper.writefunc(fd), ...)
    if not ok then
        -- if err == Sockethelper.socket_error , that means socket closed.
        Skynet.error(string.format("fd = %d, %s", fd, err))
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

local function on_message(url, args, body, header, ip)
    local auth = header.authorization
    local api = handler.api[url]
    if api then
        local ret, data = Util.try(function()
            return handler:unpack(body, url)
        end)
        if not ret then
            return '{"err":2, "desc":"body error"}'
        end
        ret = 0
        local uid = handler.auth and handler.auth(handler, auth)
        if api.auth and not uid then
            return string.format('{"err":%d}', errcode.AUTH_FAIL)
        end
        if not Util.try(function()
            ret = api.cb(handler, args, data, uid, ip, header)
        end) then
        ret = '{"err":3, "desc":"server traceback"}'
        end
        return handler:pack(ret or 0)
    else
        return '{"err":1, "desc":"api not exist"}'
    end
end

Skynet.start(function()
    Skynet.dispatch("lua", function (_,_,fd, ip)
        if fd == "hotfix" then
            handler = Hotfix.module(handler_path)
            return
        end
        Socket.start(fd)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = Httpd.read_request(Sockethelper.readfunc(fd), nil)
        --Util.printdump(header)
        Skynet.error(string.format("recv code:%s, url:%s, method:%s, header:%s", code, url, method, header))
        if code then
            if code ~= 200 then
                response(fd, code)
            else
                local data
                local _, query = Url.parse(url)
                if query then
                    data = Url.parse_query(query)
                end
                ip = header['x-real-ip'] or string.match(ip, "[^:]+")
                response(fd, code, on_message(url, data, body, header, ip), {["Access-Control-Allow-Origin"] = "*"})
            end
        else
            if url == Sockethelper.socket_error then
                Skynet.error("socket closed")
            else
                Skynet.error(url)
            end
        end
        Socket.close(fd)
    end)
    handler:init(gate)
    Hotfix.reg()
end)

elseif mode == "gate" then

local server
if server_path then
    server = require(server_path)
end

local CMD = {}
function CMD.hotfix()
    server = Hotfix.module(server_path)
    return Util.NORET
end

Skynet.start(function()
    if server then
        server:start()
    end

    local agent = {}
    for i= 1, preload do
        agent[i] = Skynet.newservice(SERVICE_NAME, "agent", server_path, handler_path, port, preload, Skynet.self())
    end
    local balance = 1
    local fd = Socket.listen("0.0.0.0", port)
    Socket.start(fd , function(_fd, ip)
        if Conf.whitelist and not Whitelist.check(ip) then
            Socket.start(_fd)
            Skynet.error(string.format("not in whitelist:%s", ip))
            response(_fd, 403)
            Socket.close(_fd)
            return
        end
        if Conf.blacklist and Blacklist.check(ip) then
            Socket.start(fd)
            Skynet.error(string.format("in blacklist:%s", ip))
            response(fd, 403)
            Socket.close(fd)
            return
        end
        --Skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        Skynet.send(agent[balance], "lua", fd, ip)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)

    Skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
        local f = assert(CMD[cmd] or server[cmd], cmd)
        if type(f) == "function" then
            Util.ret(f(server, subcmd, ...))
        else
            Util.ret(f[subcmd](f, ...))
        end
    end)

    Hotfix.reg()
end)

else
    assert(false, "mode error")
end
