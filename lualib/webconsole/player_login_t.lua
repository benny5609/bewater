local Class = require "class"
local Log = require "log"
local trace = Log.trace("webconsole")

local M = Class("PlayerLogin")
function M:ctor(player)
    self.player = player
end

function M:c2s_login()
    trace("webconsole login")
end

return M
