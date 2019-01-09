local map = {}
return setmetatable({}, {
    __index = function(_, k)
        local ctx = map[k] or setmetatable({}, {__mode = "kv"})
        map[k] = ctx
        return ctx[coroutine.running()]
    end,
    __newindex = function(_, k, v)
        local ctx = map[k] or setmetatable({}, {__mode = "kv"})
        map[k] = ctx
        ctx[coroutine.running()] = v
    end
})
