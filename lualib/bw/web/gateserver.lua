local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local bewater       = require "bw.bewater"
local conf          = require "conf"
local whitelist     = require "bw.ip.whitelist"
local blacklist     = require "bw.ip.blacklist"
local errcode       = require "def.errcode"

require "bw.ip.ip_country"

local function response(fd, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", fd, err))
    end
end

local gateserver = {}

local agents = {}
local CMD = {}
function CMD.call_agent(...)
    return skynet.call(agents[1], "lua", ...)
end

function CMD.call_all_agent(...)
    for _, agent in pairs(agents) do
        skynet.pcall(agent, "lua", ...)
    end
end

function gateserver.start(server, agentname, port, preload)
    skynet.start(function()
        bewater.reg_code()
        for i= 1, preload or 10 do
            agents[i] = skynet.newservice(agentname)
        end
        local balance = 1
        local fd = socket.listen("0.0.0.0", port)
        socket.start(fd , function(_fd, ip)
            if conf.whitelist and not whitelist.check(ip) then
                socket.start(_fd)
                skynet.error(string.format("not in whitelist:%s", ip))
                response(_fd, 403)
                socket.close(_fd)
                return
            end
            if conf.blacklist and blacklist.check(ip) then
                socket.start(fd)
                skynet.error(string.format("in blacklist:%s", ip))
                response(fd, 403)
                socket.close(fd)
                return
            end
            skynet.error(string.format("%s connected, pass it to agent :%08x", _fd, agents[balance]))
            skynet.send(agents[balance], "lua", _fd, ip)
            balance = balance + 1
            if balance > #agents then
                balance = 1
            end
        end)

        skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
            if CMD[cmd] then
                return bewater.ret(CMD[cmd](subcmd, ...))
            end
            local f = assert(server[cmd], cmd)
            if type(f) == "function" then
                bewater.ret(f(subcmd, ...))
            else
                bewater.ret(f[subcmd](f, ...))
            end
        end)

    end)
end

return gateserver
