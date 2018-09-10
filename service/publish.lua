local skynet = require "skynet"
local conf = require "conf"
local util = require "util"
require "bash"

local nodename = ...

local function publish(pconf, confname)
    if conf.remote_host then
        skynet.error("请在开发模式下发布!")
        return 
    end
    bash "rm -rf ../tmp"

    local tmp = "../tmp/"..confname
    local common = "../common"
    local projname = string.match(bash("cd %s && pwd", conf.workspace), "(%w+)\n")
    local proj = tmp.."/proj/"..projname
    bash("mkdir -p %s", tmp)    
    bash("cd %s && mkdir -p skynet common proj/%s", tmp, projname)
    bash("cp -r skynet luaclib lualib service cservice %s/skynet", tmp)
    bash("cp -r %s/lualib %s/luaclib %s/service %s/common", common, common, common, tmp)
    bash("cp -r %s/etc %s/script %s/service %s/shell %s", 
        conf.workspace, conf.workspace, conf.workspace, conf.workspace, proj)

    -- 配置文件
    pconf.workspace = string.format("%s/proj/%s/", pconf.remote_path, projname)
    local str = "return ".. util.dump(pconf)
    local file = io.open(proj.."/script/conf.lua", "w+")
    file:write(str)
    file:close()

    local file = io.open(proj.."/etc/"..pconf.etcname..".cfg", "r")
    local str = file:read("*a")
    file:close()
    str = string.gsub(str, "workspace = [^\n]+", string.format('workspace = "../proj/%s/"', projname))
    str = string.gsub(str, "clustername = [^\n]+", string.format('clustername = "%s"', pconf.clustername))
    file = io.open(proj.."/etc/"..pconf.etcname..".cfg", "w")
    file:write(str)
    file:close()

    -- 启动脚本
    local str = string.format("sh %s/proj/%s/shell/run.sh %s", pconf.remote_path, projname, pconf.etcname)
    bash("echo %s > %s/start.sh", str, tmp)
    bash("chmod 775 %s/start.sh", tmp)

    -- 停机脚本
    local str = string.format("sh %s/proj/%s/shell/stop.sh %s", pconf.remote_path, projname, pconf.etcname)
    bash("echo %s > %s/stop.sh", str, tmp)
    bash("chmod 775 %s/stop.sh", tmp)
   
    -- 发布
    bash("ssh -p %s %s mkdir -p %s", pconf.remote_port, pconf.remote_host, pconf.remote_path)
    bash("scp -rpB -P %s %s/* %s:%s ", pconf.remote_port, tmp, pconf.remote_host, pconf.remote_path)
    --bash('rsync -e "ssh -i ~/.ssh/id_rsa" -cvropg --copy-unsafe-links %s %s:%s', tmp, pconf.remote_host, pconf.remote_path)

    -- 删除临时目录
    bash "rm -rf ../tmp"
end

skynet.start(function()
    if nodename then
        local pconf = require("publish."..nodename)
        publish(pconf, nodename)
    else
        local ret = bash("cd %s/script/publish && ls", conf.workspace) 
        for filename in string.gmatch(ret, "([^\n]+).lua") do
            local pconf = require("publish."..filename)
            publish(pconf, filename)
        end

    end
end)
