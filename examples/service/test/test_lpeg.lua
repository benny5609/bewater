local lpeg = require "lpeg"
local log = require "bw.log"

local trace = log.trace("test_lpeg")
return function()
    local match = lpeg.match
    local P = lpeg.P

    print(match(P("be"), "bewater"))
    print(match(P(1), "bewater"))
    print(match(P(-8), "bewater"))
    print(match(P("bewater")*P(1)*P("test"), "bewater-test"))

end
