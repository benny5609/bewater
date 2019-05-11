local bewater = require "bw.bewater"
return function()
    local tbl = bewater.protect({
        a = 1,
        b = 2,
        c = {
            aa = 1,
            bb = {
                ccc = 2,
            }
        }
    }, 1)

    tbl.a = 100
    --tbl.c = 111
    --print(tbl.c)
    --print(tbl.c.bb.aaa)
end
