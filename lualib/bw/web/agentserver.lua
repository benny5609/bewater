local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local bewater       = require "bw.bewater"
local errcode       = require "def.errcode"
local util          = require "bw.util"

require "bw.ip.ip_country"

local function response(fd, ...)
    local writefunc = sockethelper.writefunc(fd)
    local ok, err = httpd.write_response(writefunc, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", fd, err))
    end
end


local function on_message(handler, url, args, body, header, ip)
    local auth = header.authorization
    local api = handler.api[url]
    if api then
        local ret, data = bewater.try(function()
            return handler.unpack(body, url)
        end)
        if not ret then
            return {
                err = errcode.BODY_ERROR,
                desc = "body error"
            }
        end
        ret = {}
        local uid = handler.auth and handler.auth(auth)
        if api.auth and not uid then
            return {
                err = errcode.AUTH_FAIL,
                desc = "authorization fail",
            }
        end
        if api.data then
            for k, t in pairs(api.data) do
                if t == "str" then
                    if type(data[k]) ~= "string" then
                        return {
                            err = errcode.ARGS_ERROR,
                            desc = string.format("args error, %s must string", k),
                        }
                    end
                elseif t == "str?" then
                    if data[k] and type(data[k]) ~= "string" then
                        return {
                            err = errcode.ARGS_ERROR,
                            desc = string.format("args error, %s must string", k),
                        }
                    end
                elseif t == "num" then
                    if type(data[k]) ~= "number" then
                        return {
                            err = errcode.ARGS_ERROR,
                            desc = string.format("args error, %s must number", k),
                        }
                    end
                elseif t == "num?" then
                    if data[k] and type(data[k]) ~= "number" then
                        return {
                            err = errcode.ARGS_ERROR,
                            desc = string.format("args error, %s must number", k),
                        }
                    end
                else
                    util.printdump(data)
                    error(string.format("api %s def type %s error", api, t))
                end
            end
        end
        if not bewater.try(function()
            local func = require(string.sub(url, 2, -1))
            assert(func, url)
            ret = func(args, data, uid, ip, header) or {}
            if type(ret) == "number" then
                ret = {err = ret}
                if ret.err ~= 0 then
                    ret.desc = errcode.describe(ret.err)
                end
            end
        end) then
            return {
                err = errcode.TRACEBACK,
                desc = "server traceback"
            }
        end
        if type(ret) == "table" then
            ret.err = ret.err or 0
        end
        return ret
    else
        return {
            err = errcode.API_NOT_EXIST,
            desc = "api not exist"
        }
    end
end

local function resp_options(fd, header)
    response(fd, 200, nil, {
        ['Access-Control-Allow-Origin'] = header['origin'],
        ['Access-Control-Allow-Methons'] = 'PUT, POST, GET, OPTIONS, DELETE',
        ['Access-Control-Allow-Headers'] = header['access-control-request-headers'],
        --['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, content-Type, Accept, Authorization',
    })
    socket.close(fd)
end

local agentserver = {}
function agentserver.start(handler)
    -- handler 需要提供
    -- hander.api = {[[/api/xxx/ooo]] = func}
    -- hander.auth = function(auth) return uid end -- 授权
    -- 如果是非字符串，handler需要提供pack和unpack方法
    handler.pack = handler.pack or function (data)
        return data
    end
    handler.unpack = handler.unpack or function (data)
        return data
    end

    skynet.start(function()
        bewater.reg_code()
        skynet.dispatch("lua", function (_,_, ...)
            local args = {...}
            if type(args[1]) == "string" then
                local func = assert(handler[args[1]], args[1])
                return bewater.ret(func(...))
            end
            local fd, ip = ...
            socket.start(fd)
            -- limit request body size to 8192 (you can pass nil to unlimit)
            local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), nil)
            --util.printdump(header)
            skynet.error(string.format("recv code:%s, url:%s, method:%s, header:%s", code, url, method, header))
            if method == "OPTIONS" then
                return resp_options(fd, header)
            end
            if code then
                if code ~= 200 then
                    response(fd, code)
                else
                    local data
                    local _, query = urllib.parse(url)
                    if query then
                        data = urllib.parse_query(query)
                    end
                    ip = header['x-real-ip'] or string.match(ip, "[^:]+")
                    response(fd, code, handler.pack(on_message(handler, url, data, body, header, ip)),
                    {
                        ['Access-Control-Allow-Origin'] = header['origin'],
                        ['Access-Control-Allow-Methons'] = 'PUT, POST, GET, OPTIONS, DELETE',
                        ['Access-Control-Allow-Headers'] = header['access-control-request-headers']
                    })

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
    end)
end
return agentserver
