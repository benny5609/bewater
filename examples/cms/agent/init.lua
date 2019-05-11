local agentserver   = require "bw.server.http_gate"
local handler       = require "sys.cms.handler"

agentserver.start(handler)
