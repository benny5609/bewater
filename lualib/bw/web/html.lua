local html = {}

local function parse(param)
    local str = ""
    for k, v in pairs(param or {}) do
        str = str .. k .. '="' .. v .. '"'
    end
    return str
end

setmetatable(html, {
    __index = function(t, k)
        local v = rawget(t, k)
        if v then
            return v
        else
            return function(ctx, param)
                return string.format('<%s %s>%s</%s>', k, parse(param), ctx, k)
            end
        end
    end
})

return html
