local skynet = require "skynet"
local log = require "bw.log"
return function()
    log.debugf("this is debug log")
    log.infof("this is info log")
    log.warningf("this is wraning log")
    log.errorf("this is error log")
    local a = {aa = 1, bb = {cc = 2, dd = 333}}
    log.info("a:", a)
    assert(false, "this is traceback")
end
