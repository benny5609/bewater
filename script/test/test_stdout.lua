local skynet    = require "skynet"
local sname     = require "bw.sname"

return function()
    skynet.call(sname.STDOUT, "lua", "run", "cp -rvf ~/code ~/backup")
    skynet.fork(function()
        local offset = 0
        local str = ""
        local eof = false
        while true do
            print("running")
            str, offset, eof = skynet.call(sname.STDOUT, "lua", "log", offset)  
            print(str)
            print(offset)
            if eof then
                break
            end
            skynet.sleep(10)
        end
    end)
end

