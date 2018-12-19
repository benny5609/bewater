local skynet = require "skynet"
local env = nil
local function run(source)
    local f, err = load(source, "@inject", "bt", env)
    if not f then
        print(err)
        return false
    end

    local r, err = xpcall(f, debug.traceback)
    if not r then
        print(err)
    end
    return r
end

local function _code_dispatch(_, addr, source)
    skynet.error('on run', addr)
    local injectcode = require "skynet.injectcode"
    return skynet.retpack(injectcode(source, nil, 1))
    --return skynet.retpack(run(source))
end

local M = {}
function M.REG(_env)
    local REG = skynet.register_protocol
    REG {
        name = 'code',
        id = 12,
        unpack = skynet.unpack,
        pack = skynet.pack,
        dispatch = _code_dispatch,
    }
    env = _env
    
end

return M
