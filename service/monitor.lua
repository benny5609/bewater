local skynet  = require "skynet.manager"
local bewater = require "bw.bewater"
local log     = require "bw.log"
local trace   = log.trace("monitor")

local table_insert = table.insert
local table_remove = table.remove

local addr_list = {}

local CMD = {}
function CMD.register(addr)
    table_insert(addr_list, addr)
end

function CMD.unregister(addr)
    for i, v in ipairs(addr_list) do
        if v == addr then
            table_remove(v, i)
        end
    end
end

function CMD.shutdown(force)
    for _, v in pairs(addr_list) do
        if force then
            bewater.try(function()
                skynet.call(v, "lua", "shutdown", force)
            end)
        else
            skynet.call(v, "lua", "shutdown", force)
        end
    end
    skynet.sleep(100)
end

bewater.start(CMD)
