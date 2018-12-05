local class = require "class"
local log = require "log"
local trace = log.trace("webconsole")

local M = class("PlayerLogin")
function M:ctor(player)
    self.player = player
end

function M:c2s_login()
    trace("webconsole login")
end

return M
