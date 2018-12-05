local class             = require "class"
local network_t         = require "ws.network_t"
local player_skynet_t   = require "webconsole.player_skynet_t"
local player_login_t    = require "webconsole.player_login_t"

local M = class("Player")
function M:ctor()
    self.net = network_t.new(self)
    self.login = player_login_t.new(self)
    self.skynet = player_skynet_t.new(self)
end
return M
