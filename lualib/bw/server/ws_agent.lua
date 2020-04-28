local skynet    = require "skynet"
local socket    = require "skynet.socket"
local websocket = require "http.websocket"
local json      = require "cjson.safe"
local log       = require "bw.log"
local bewater   = require "bw.bewater"
local errcode   = require "def.errcode"

local protocol, pack, unpack, process

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

local ws = {}

function ws.connect(id)
    log.debugf("ws connect from: %s", id)
end

function ws.handshake(id, header, url)
    local addr = websocket.addrinfo(id)
    log.debugf("ws handshake from: %s, url:%s, addr:%s", id, url, addr)
end

function ws.message(id, msg)
    log.debugf("on message, id:%s, msg:%s", id, msg)
    local req = unpack(msg)
    log.debug("unpack", req)

    local function response(data)
        if type(data) == "number" then
            data = {err = data}
        end
        if data.err ~= 0 then
            data.desc = errcode.describe(data.err)
        end

        websocket.write(id, pack {
            name = req.name,
            session = req.session,
            data = data,
        })
    end

    local mod, name = string.match(req.name, "(%w+)%.(%w+)")
    if not process[mod] or not process[mod][name] then
        return response(errcode.PROCESS_NOT_EXIST)
    end
    if not bewater.try(function()
        local func = process[mod][name]
        response(func(req.data) or 0)
    end) then
        return response(errcode.TRACEBACK)
    end
end

function ws.ping(id)
    print("ws ping from: " .. tostring(id) .. "\n")
end

function ws.pong(id)
    print("ws pong from: " .. tostring(id))
end

function ws.close(id, code, reason)
    print("ws close from: " .. tostring(id), code, reason)
end

function ws.error(id)
    print("ws error from: " .. tostring(id))
end

local M = {}
function M.start(handler)
    protocol = handler.protocol or "ws"
    pack     = pack or default_pack
    unpack   = unpack or default_unpack
    process  = assert(handler.process)

    skynet.start(function ()
        skynet.dispatch("lua", function (_,_, id, addr)
            log.debug(id, protocol, addr)
            local ok, err = websocket.accept(id, ws, protocol, addr)
            if not ok then
                print(err)
            end
        end)
    end)
end

return M
