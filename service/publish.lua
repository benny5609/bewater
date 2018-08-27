local skynet = require "skynet"
local conf = require "conf"
local util = require "util"
require "bash"

local function publish(pconf, confname)
    local tmp = "../tmp/"..confname
    local common = "../common"
    local proj = string.match(bash("cd %s && pwd", conf.workspace), "(%w+)\n")
    local proj = tmp.."/proj/"..proj
    bash("mkdir -p %s", tmp)    
    bash("cd %s && mkdir -p skynet common proj/%s", tmp, proj)
    bash("cp -r skynet luaclib lualib service cservice %s/skynet", tmp)
    bash("cp -r %s/lualib %s/luaclib %s/service %s/common", common, common, common, tmp)
    bash("cp -r %s/* %s", conf.workspace, proj)
    
    local str = "return ".. util.dump(pconf)
    local file = io.open(proj.."/script/conf.lua", "w+")
    file:write(str)
    file:close()
   
    bash("ssh -p %s %s mkdir -p %s", pconf.remote_port, pconf.remote_host, pconf.workspace)
    bash("scp -r -P %s %s/* %s:%s ", pconf.remote_port, tmp, pconf.remote_host, pconf.workspace)
end

skynet.start(function()
    local ret = bash("cd %s/script/publish && ls", conf.workspace) 
    for filename in string.gmatch(ret, "([^\n]+).lua") do
        local pconf = require("publish."..filename)
        publish(pconf, filename)
    end
end)
