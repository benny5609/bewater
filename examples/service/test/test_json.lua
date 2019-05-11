local skynet = require "skynet"
local json = require "cjson"
return function()
    skynet.error(json.encode({}))
    skynet.error(json.encode_empty_table_as_array(true))
    skynet.error(json.encode({}))
    skynet.error(json.encode({}))
end
