local layui = {}
function layui.row(ctx, ...)
    local param = table.concat({...}, " ")
    return string.format('<div class="layui-row %s">%s</div>', param, ctx)
end

function layui.form(ctx, ...)
    local param = table.concat({...}, " ")
    return string.format('<form class="layui-form %s">%s</form>', param, ctx)
end

function layui.table(head, data, ...)
    local param = table.concat({...}, " ")
    if #param == 0 then
        param = "mag0"
    end
    local str = ""
    if head then
        str = str .. "<thead><tr>"
        for _, v in ipairs(head) do
            str = str .. string.format("<th>%s</th>", v)
        end
        str = str .. "</tr></thead>"
    end

    for _, tr in ipairs(data) do
        str = str .. "<tr>"
        for _, td in ipairs(tr) do
            str = str .. "<td>"..td.."</td>"
        end
        str = str .. "</tr>"
    end
    return string.format('<table class="layui-table %s">%s</table>', param, str)
end

return layui
