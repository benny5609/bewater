local agentserver   = require "bw.web.agentserver"
local handler       = require "sys.cms.handler"

agentserver.start(handler)
