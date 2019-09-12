local lfs = require "lfs"
local log = require "bw.log"
return function()
    log.debug("test lfs")
    for file in lfs.dir('./') do
        log.debug(file)
    end
end
