local bash = require "bw.bash"
local log  = require "bw.log"

return function()
    log.debug "test bash"
    local path = "./"
    log.debug(bash.execute("ls -al ${path}"))
end
