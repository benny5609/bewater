local factory   = require "bw.orm.factory"
local util      = require "bw.util"
local log       = require "bw.log"

local trace = log.trace("test_factory")

return function()
    trace("test_factory")
    local obj = factory.create_obj("role", {
        roleid = 123
    })
    util.printdump(obj)
    obj = factory.create_obj("user", {
        uid = 10001,
        aaa = 11,
    })
    util.printdump(obj)
    local new_obj = factory.extract_data(obj)
    obj.token = "xxoo"
    if util.cmp_table(new_obj, obj) then
        trace("no change")
    else
        trace("dirty")
    end
end
