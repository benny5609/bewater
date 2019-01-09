local skynet    = require "skynet"
local class     = require "bw.class"
local bash      = require "bw.bash"
local log       = require "bw.log"
local conf      = require "conf"

local trace = log.trace("clusternode")

local mt = {}
function mt:ctor(name, clustername, workspace)
    self.name = name
    self.clustername = clustername
    self.workspace = workspace or conf.workspace
    self.pid_file = string.format("%s/../%s/log/pid/%s.pid",
        self.workspace, name, clustername)
end

function mt:run()
    if not bash.file_exists(self.pid_file) then
        bash.bash("sh %s/../%s/shell/run.sh %s",
            self.workspace, self.name, self.clustername)
        skynet.sleep(10)
        while not bash.file_exists(self.pid_file) do
            trace("%s<%s> is launching.", self.name, self.clustername)
            skynet.sleep(100)
        end
        trace("%s<%s> is running.", self.name, self.clustername)
    else
        trace("%s<%s> is already runed", self.name, self.clustername)
    end
end

function mt:kill()
    if bash.file_exists(self.pid_file) then
        bash.bash("cat %s | xargs kill -1", self.pid_file)
        skynet.sleep(10)
        while bash.file_exists(self.pid_file) do
            trace("%s<%s> is going down.", self.name, self.clustername)
            skynet.sleep(100)
        end
        trace("%s<%s> is down.", self.name, self.clustername)
    else
        trace("%s<%s> is not running", self.name, self.clustername)
    end
end

function mt:restart()
    self:kill()
    self:run()
end

return class(mt)
