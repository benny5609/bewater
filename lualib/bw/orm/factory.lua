local skynet  = require "skynet"
local orm     = require 'bw.orm.orm'
local typedef = require 'bw.orm.typedef'

-- init
local type_list = typedef.parse("typedef", skynet.getenv "TYPEDEF")
orm.init(type_list)

-- apis
local M = {}
function M.create_obj(cls_type, data)
    return orm.create(cls_type, data)
end

-- copy and remove metatable
function M.extract_data(obj)
    if getmetatable(obj) == nil then
        return obj
    end

    local ret = {}
    for k, v in pairs(obj) do
        if type(v) == "table" then
            ret[k] = M.extract_data(v)
        else
            ret[k] = v
        end
    end
    return ret
end

function M.to_mongo(obj)
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
            local tmp = M.to_mongo(v)
            ret[key] = tmp
        else  -- v is atomic
            if cls.attrs then --obj is struct
                local sub_cls = cls.attrs[k]
                if sub_cls.default ~= v then  --v equal to field default value
                    ret[key] = v
                end
            else  --obj is map
                ret[key] = v
            end
        end
    end
    return ret
end

return M
