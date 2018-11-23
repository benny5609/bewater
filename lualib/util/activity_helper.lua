local Skynet   = require "skynet"
local Schedule = require "schedule"

local M = {}
-- t:{month=, day=, wday=, hour= , min=} wday
function M.schedule(t, cb)
    assert(type(t) == "table")
    assert(cb)
    Skynet.fork(function()
        while true do
            Schedule.submit(t)
            cb()
            Skynet.sleep(100)
        end
    end)
end
return M
