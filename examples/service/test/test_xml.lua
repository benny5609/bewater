local lua2xml = require "bw.xml.lua2xml"
local xml2lua = require "bw.xml.xml2lua"
local log     = require "bw.log"

return function()
    local ok = {
        return_code = "SUCCESS",
        return_msg  = "OK",
    }
    local str = lua2xml.encode("xml", ok, true)
    log.debug(str)
    log.debug(xml2lua.decode(str).xml)
end
