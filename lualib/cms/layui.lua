local layui = {}

local function parse(param)
    local str = ""
    for k, v in pairs(param or {}) do
        str = str .. k .. '="' .. v .. '"'
    end
    return str
end

function layui.div(ctx, class)
    return string.format('<div class="%s">%s</div>', class or "", ctx or "")
end

function layui.row(ctx, class)
    return string.format('<div class="layui-row %s">%s</div>', class or "", ctx or "")
end

function layui.form(item_list, class, param)
    local ctx = ""
    for _, item in pairs(item_list) do
        ctx = ctx .. '<div class = "layui-form-item input-item">' .. item .. '</div>'
    end
    return string.format('<form class="layui-form %s" %s>%s</form>', class or "", parse(param), ctx or "")
end

function layui.button(ctx, class)
    return string.format('<button class="layui-button %s">%s</button>', class or "", ctx or "")
end

function layui.form_label(ctx, class)
    return string.format('<label class="layui-form-label %s">%s</label>', class or "", ctx or "")
end

function layui.input_block(ctx, class)
    return string.format('<div class="layui-input-block %s">%s</div>', class or "", ctx or "")
end

function layui.input(ctx, class, param)
    return string.format('<input class="%s" %s>%s</input>',
        class or "", parse(param), ctx or "")
end

function layui.label(ctx, class, param)
    return string.format('<label class="%s" %s>%s</label>',
        class or "", parse(param), ctx or "")
end

function layui.table(head, tbl, class, colgroup)
    local str = ""
    if head then
        str = str .. "<thead><tr>"
        for _, v in ipairs(head) do
            str = str .. string.format("<th>%s</th>", v)
        end
        str = str .. "</tr></thead>"
    end
    if colgroup then
        str = str .. '<colgroup>'
        for _, col in ipairs(colgroup) do
            str = str .. '<col ' .. col .. '>'
        end
        str = str .. '</colgroup>'
    end
    str = str .. '<tbody>'
    for _, tr in ipairs(tbl) do
        str = str .. "<tr>"
        for _, td in ipairs(tr) do
            str = str .. "<td>"..td.."</td>"
        end
        str = str .. "</tr>"
    end
    str = str .. '</tbody>'
    return string.format('<table class="layui-table %s">%s</table>', class or "mag0", str)
end

return layui
