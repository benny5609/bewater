local log  = require "bw.log"
local http = require "bw.http"
return function()
    local s = 'title=test&aaa=1&bb=2www'
    log.debug(http.decode_uri(s))
end
