local bash = require "bw.bash"
local log  = require "bw.log"

return function()
    log.debug "test bash"
    local path = "./"
    log.debug(bash.execute("ls -al ${path}"))

    local cpu = string.match(bash.execute([[top -n 1 | grep Cpu | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g"]]), "([%d%.]+) us")
    log.debug("cpu", cpu)

    local total_mem, used_mem = string.match(bash.execute("free"), "Mem:[ ]+(%d+)[ ]+(%d+)")
    log.debugf("mem:%s/%s", used_mem, total_mem)
end
