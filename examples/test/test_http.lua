local http = require "bw.web.http_helper"
local util = require "bw.util"
return function()
    local s = 'title=test&aaa=1&bb=2www'
    util.printdump(http.decode_uri(s))
end
