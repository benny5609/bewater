local skynet = require "skynet"
local json   = require "cjson"
local log    = require "bw.log"

return function()
    log.debug(json.encode({}))
    log.debug(json.encode_empty_table_as_array(true))
    log.debug(json.encode({}))
    log.debug(json.encode({}))
end
