local skynet    = require "skynet"
local bewater   = require "bw.bewater"
local log       = require "bw.log"
local env       = require "env"

local trace = log.trace("hall")

local GATE

skynet.start(function()
    GATE = skynet.newservice("gate")
    env.GATE = GATE
end)
