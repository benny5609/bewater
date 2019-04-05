local bewater 	= require "bw.bewater"
return function(_, data)
    print("debug inject!", data.addr, data.code)
    local _, output = bewater.inject(data.addr, data.code)
    return {output = output}
end
