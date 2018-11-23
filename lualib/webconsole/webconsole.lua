local Conf   = require "conf"
local Log    = require "log"

local trace = Log.trace("webconsole")

local M = {}
function M:start()
    trace("后台地址: %s:%d", Conf.webconsole.host, Conf.webconsole.port)
end

return M
