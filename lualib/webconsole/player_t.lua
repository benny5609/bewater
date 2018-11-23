local Class         = require "class"
local Network       = require "ws.network_t"
local PlayerSkynet  = require "webconsole.player_skynet_t"
local PlayerLogin   = require "webconsole.player_login_t"

local M = Class("Player")
function M:ctor()
    self.net = Network.new(self)
    self.login = PlayerLogin.new(self)
    self.skynet = PlayerSkynet.new(self)
end
return M
