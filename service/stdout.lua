local skynet = require "skynet"
local conf   = require "conf"

local mode = ...
if mode == 'agent' then
    local lock = require "bw.lock"
    local run_lock = lock.new()
    local runing = false
    local path
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, expr, filename)
            run_lock:lock()
            path = filename or conf.workspace.."/log/stdout.log" 
            os.execute('echo "%s" > %s', expr, path)
            skynet.retpack()
            expr = string.format('%s >%s 2>&1', expr, path)
            os.execute(expr)
            os.execute('echo "==EOF==" >>'..path)
            run_lock:unlock()
        end)
    end)
else
    local bewater = require "bw.bewater"
    local agents = {}
    local CMD = {}
    function CMD.run(expr, filename)
        filename = filename or conf.workspace.."/log/stdout.log"
        local agent = agents[filename] or skynet.newservice(SERVICE_NAME, "agent")
        agents[filename] = agent
        skynet.call(agent, "lua", expr, filename)
    end
    function CMD.log(offset, filename)
        filename = filename or conf.workspace.."/log/stdout.log"
        local file = io.open(filename, "r")
        if not file then
            return "", 0, false
        end
        file:seek("set", offset or 0)
        local str = file:read("a")
        offset = file:seek()
        file:close()
        return str, offset, string.match(str, "==EOF==") ~= nil
    end
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local f = assert(CMD[cmd], cmd)
            bewater.ret(f(...))
        end)
    end)
end

