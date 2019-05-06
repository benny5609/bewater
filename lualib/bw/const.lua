local meta = {
    __newindex = function(_, k)
        error(string.format("readonly:%s", k), 2)
    end,
    __index = function(t, k)
        local v = rawget(t, k)
        assert(v, string.format("illegal key:%s", k))
        return v
    end,
}

local function const(t, depth)
    setmetatable(t, meta)
    if depth and depth > 0 then
        for _, v  in pairs(t) do
            if type(v) == "table" then
                const(v, depth - 1)
            end
        end
    end
    return t
end
return const
