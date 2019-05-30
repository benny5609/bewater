local factory   = require "bw.orm.factory"
local util      = require "bw.util"
local log       = require "bw.log"

return function()
    log.debug("test_factory")
    local obj = factory.create_obj("role", {
        roleid = 123
    })
    log.debug(obj)
    obj = factory.create_obj("user", {
        uid = 10001,
        aaa = 11,
    })
    log.debug(obj)
    local new_obj = factory.extract_data(obj)
    obj.token = "xxoo"
    if util.cmp_table(new_obj, obj) then
        log.debug("no change")
    else
        log.debug("dirty")
    end
end
