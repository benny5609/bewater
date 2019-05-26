local skynet = require "skynet"
local log = require "bw.log"
return function()
    local logger = skynet.newservice "syslog"
    log.debugf("this is debug %d log", skynet.self())
    log.infof("this is info %d log", skynet.self())
    log.warningf("this is wraning %d log", skynet.self())
    log.errorf("this is error %d log", skynet.self())
    assert(false, "this is traceback")
end
