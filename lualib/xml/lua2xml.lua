local string_format = string.format
local M = {}
function M.add(k, v)
    local str = '<'..k..'>'
    if type(v) == "table" then
        for kk, vv in pairs(v) do
            str = str .. M.add(kk, vv)
        end
    else
        str = str .. v
    end
    str = str..'</'..k..'>'
    return str
end

-- 不带属性的key-value
function M.kv(t)
    return M.add("xml", t)
end

-- 带属性的key-value
function M.attr_kv(t)
    -- todo 
end
return M
