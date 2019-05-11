local util = require "bw.util"
local http = require "bw.http"
return function()
    local s = 'title=test&aaa=1&bb=2www'
    util.printdump(http.decode_uri(s))
end
