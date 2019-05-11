local ctx = require "bw.context"
return function()
    assert(not ctx.aaa)
    ctx.aaa = 222
    assert(ctx.aaa == 222)
    return true
end
