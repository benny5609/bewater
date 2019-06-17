local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local json          = require "cjson.safe"
local bewater       = require "bw.bewater"
local util          = require "bw.util"
local log           = require "bw.log"
local errcode       = require "def.errcode"

local smatch  = string.match
local sformat = string.format
local sgsub   = string.gsub

local api = {}

local function default_pack(ret)
    if type(ret) == "table" then
        ret.err = ret.err or 0
        return json.encode(ret)
    else
        return json.encode({err = ret})
    end
end

local function default_unpack(str)
    return json.decode(str)
end

local function default_auth(p)
    error("auth function not provide")
end

local function response(fd, ...)
    local writefunc = sockethelper.writefunc(fd)
    local ok, err = httpd.write_response(writefunc, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        log.errorf("fd = %d, %s", fd, err)
    end
end

local function on_message(url, args, body, header, ip)
    local authorization = header.authorization
    local process = api[url]
    if process then
        local pack   = process.pack or default_pack
        local unpack = process.unpack or default_unpack
        local auth   = process.auth and default_auth

        local function errf(err, fmt, ...)
            return pack {
                err = err,
                desc = string.format(fmt, ...),
                url = url
            }
        end

        local ret, data = bewater.try(function()
            return unpack(body, url)
        end)
        if not ret then
            return errf(errcode.BODY_ERROR, "body error")
        end
        ret = {}
        local uid = process.auth
        if process.auth and auth then
            uid = auth(authorization)
            if not uid then
                return errf(errcode.AUTH_FAIL, "authorization fail")
            end
        end
        if process.data then
            if not data then
                return errf(errcode.ARGS_ERROR, "data nil")
            end
            for k, t in pairs(process.data) do
                if t then
                    if smatch(t, "?") then
                        t = sgsub(t, "?", "")
                        if data[k] and type(data[k]) ~= t then
                            return errf(errcode.ARGS_ERROR, "args error, %s must %s", k, t)
                        end
                    else
                        if type(data[k]) ~= t then
                            return errf(errcode.ARGS_ERROR, "args error, %s must %s", k, t)
                        end
                    end
                end
            end
        end
        if not bewater.try(function()
            local func = process.handler
            ret = process.handler(args, data, uid, ip, header) or {}
            if type(ret) == "number" then
                ret = {err = ret}
                if ret.err ~= 0 then
                    ret.desc = errcode.describe(ret.err)
                    ret.url = url
                end
            end
        end) then
            return errf(errcode.TRACEBACK, "server traceback")
        end
        if type(ret) == "table" then
            ret.err = ret.err or 0
        end
        return pack(ret)
    else
        return default_pack({
            err = errcode.API_NOT_EXIST,
            desc = "api not exist",
            url = url,
        })
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

local M = {}
function M.start(handler)
    -- handler 需要提供
    -- 如果是非字符串，handler需要提供pack和unpack方法
    default_pack = handler.pack or default_pack
    default_unpack = handler.unpack or default_unpack
    default_auth = handler.auth or default_auth

    skynet.start(function()
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
            --log.info(header)
            log.errorf("recv code:%s, url:%s, method:%s, header:%s, body:%s",
                code, url, method, util.tbl2str(header), body)
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
                    local resp_body, resp_header = on_message(url, data, body, header, ip)
                    response(fd, code, resp_body, resp_header or {
                        ['Access-Control-Allow-Origin'] = header['origin'],
                        ['Access-Control-Allow-Methons'] = 'PUT, POST, GET, OPTIONS, DELETE',
                        ['Access-Control-Allow-Headers'] = header['access-control-request-headers']
                    })

                end
            else
                if url == sockethelper.socket_error then
                    log.debug("socket closed")
                else
                    log.debug(url)
                end
            end
            socket.close(fd)
        end)
    end)
end

function M.reg(params)
    for k, t in pairs(params.data or {}) do
        t = sgsub(t, "?", "")
        assert(t == "number" or t == "string" or t == "boolean" or t == "table",
            sformat("type def error:%s", t))
    end
    api[params.url] = {
        url     = assert(params.url),
        handler = assert(params.handler),
        pack    = params.pack,
        unpack  = params.unpack,
        auth    = params.auth,
        data    = params.data,
    }
end

return M
