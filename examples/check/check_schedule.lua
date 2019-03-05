local schedule = require "bw.schedule"
return function ()
    assert(schedule.time())
    return true
end
