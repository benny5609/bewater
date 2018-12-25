local bewater 	= require "bw.bewater"
local layui 	= require "bw.cms.layui"
local util 		= require "bw.util"
return function(_, data)
    print("debug inject!", data.addr, data.code)
    local ok, output = bewater.inject(data.addr, data.code)
    return {output = output}
end
