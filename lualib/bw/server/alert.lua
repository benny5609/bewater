-- 警报系统
local skynet      = require "skynet"
local json        = require "cjson.safe"
local clusterinfo = require "bw.util.clusterinfo"
local bewater     = require "bw.bewater"
local log         = require "bw.log"
local util        = require "bw.util"
local http        = require "bw.http"

local pid     = clusterinfo.pid
local appname = skynet.getenv 'APPNAME'
local desc    = skynet.getenv 'DESC'

local sample_html = [[
<style>
    .item-title {
        font-size: large;
        display: inline;
    }

    .item-content {
        font-size: large;
        display: inline;
    }

    .log {
        white-space: pre;
        display: inline;
        color:gray;
    }
</style>

<div>
    <div class="item-title">节点:</div>
    <div class="item-content" style="color: red;">%s</div>
</div>
<div>
    <div class="item-title">备注:</div>
    <div class="item-content" style="color: red;">%s</div>
</div>
<div>
    <div class="item-title">进程:</div>
    <div class="item-content" style="color: red;">%s</div>
</div>

<div>
    <div class="item-title">日志:</div>
    <div class="log">%s</div>
</div>
]]

local sformat = string.format
local send

local function format_html(msg)
    return sformat(sample_html, appname, desc, pid, msg)
end

local M = {}
function M.traceback(err)
    send(format_html(err))
end

function M.test(str)
    send(str)
end

function M.start(handler)
    skynet.register ".alert"

    send = assert(handler.send)
end

return M
