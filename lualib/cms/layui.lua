local layui = {}
function layui.row(ctx, class)
    return string.format('<div class="layui-row %s">%s</div>', class or "", ctx)
end

function layui.form(ctx, class)
    return string.format('<form class="layui-form %s">%s</form>', class or "", ctx)
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
