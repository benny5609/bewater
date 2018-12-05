local conf   = require "conf"
local log    = require "log"

local trace = log.trace("webconsole")

local M = {}
function M:start()
    trace("后台地址: %s:%d", conf.webconsole.host, conf.webconsole.port)
end

return M
