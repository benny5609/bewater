local schedule = require "schedule"
return function ()
    assert(schedule.time())
    return true
end
