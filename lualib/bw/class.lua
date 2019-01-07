return function(mt)
    mt.__index = mt

    local M = {}
    function M.new(...)
        local obj = setmetatable({}, mt)
        if obj.ctor then
            obj:ctor(...)
        end
        return obj
    end
    return M
end
