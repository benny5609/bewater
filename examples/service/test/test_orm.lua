local orm       = require "bw.orm.orm"
local typeof    = require "bw.orm.typedef"
local util      = require "bw.util"
local log       = require "bw.log"

return function()

    local define = [[
    RoleInfo {
        serverid number
        roleid   number
        name     string
        new      boolean
    }

    User {
        uid     number
        token   string
        self    RoleInfo
        roles   [RoleInfo]
        extends <number, RoleInfo>
    }
    ]]

    local function to_data(t)
        local ret = {}
        for k,v in pairs(t) do
            if type(v) == 'table' then
                ret[k] = to_data(v)
            else
                ret[k] = v
            end
        end
        return ret
    end

    local type_list = typeof.parse_string(define)

    log.debug("--------- type define ------------")
    log.debug(type_list)

    log.debug("--------- init cls map ------------")
    orm.init(type_list)

    log.debug("--------- cls map---------------")
    log.debug(orm.get_cls_map())

    log.debug("-----------------role")
    local role = orm.create("RoleInfo", {serverid=10001, name="standalone"})
    log.debug(to_data(role))

    log.debug("-----------------obj")
    local obj = orm.create("User", {
        uid=1,
        token="abc",
        self={a="c", serverid="3", roleid=11111, name="self", new=true},
        roles={{serverid=1, roleid=1}, {serverid=2, roleid=2}},
        extends={[3] = {serverid=3, name="extends3"}, [4] = {serverid=4, name="extends4"}}
    })
    log.debug("--------------", obj.uid)

    log.debug(to_data(obj))

    log.debug("-----------------obj+role")
    obj.roles[#obj.roles+1] = role
    log.debug(to_data(obj))

    log.debug("------------ set dirty data")
    obj.roles[2] = {a = 1}
    log.debug(to_data(obj))

    local function to_mongo(obj)
        local metatable = getmetatable(obj)
        if metatable == nil then
            return obj
        end
        local ret = {}
        local cls = metatable.__cls
        for k, v in pairs(obj) do
            local key = k
            if cls.type ~= 'list' then
                key = tostring(k)
            end
            if type(v) == "table" then
                local tmp = to_mongo(v)
                ret[key] = tmp
            else  -- v is atomic
                if cls.attrs then --obj is struct
                    local sub_cls = cls.attrs[k]
                    if sub_cls.default ~= v then --v equal to field default value
                        ret[k] = v
                    end
                else  --obj is map
                    ret[k] = v
                end
            end
        end
        return ret
    end

    log.debug("----------- to_mongo")
    log.debug(to_mongo(obj))
    log.debug("----------- to_mongo list")
    local user = orm.create("User", {
        roles = {
            {
                roleid = 0,
            },
            {
                roleid = 0,
            },
            {
                roleid = 0,
            },
        },
    })
    log.debug(to_mongo(user))
end
