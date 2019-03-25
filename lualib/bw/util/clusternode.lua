local skynet    = require "skynet"
local class     = require "bw.class"
local bash      = require "bw.bash"
local log       = require "bw.log"
local conf      = require "conf"

local trace = log.trace("clusternode")

local mt = {}
function mt:ctor(name, etc, workspace)
    self.name = name
    self.etc = etc
    self.workspace = workspace or conf.workspace
    self.pid_file = string.format("%s/log/pid/%s.pid",
        self.workspace, etc)
end

function mt:run()
    if not bash.file_exists(self.pid_file) then
        bash.bash("sh %s/shell/run.sh %s",
            self.workspace, self.etc)
        skynet.sleep(10)
        while not bash.file_exists(self.pid_file) do
            trace("%s<%s> is launching.", self.name, self.etc)
            skynet.sleep(100)
        end
        trace("%s<%s> is running.", self.name, self.etc)
    else
        trace("%s<%s> is already runed", self.name, self.etc)
    end
end

function mt:kill()
    if bash.file_exists(self.pid_file) then
        bash.bash("cat %s | xargs kill -1", self.pid_file)
        skynet.sleep(10)
        while bash.file_exists(self.pid_file) do
            trace("%s<%s> is going down.", self.name, self.etc)
            skynet.sleep(100)
        end
        trace("%s<%s> is down.", self.name, self.etc)
    else
        trace("%s<%s> is not running", self.name, self.etc)
    end
end

function mt:restart()
    self:kill()
    self:run()
end

return class(mt)
