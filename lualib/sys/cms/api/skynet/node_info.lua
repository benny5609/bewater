local skynet      = require "skynet"
local date_helper = require "bw.util.date_helper"

local desc = skynet.getenv "DESC" or "未知"
local clustername = skynet.getenv "CLUSTER_NAME" or "未知"
local gate = string.format("%s:%s", skynet.getenv "LOGIN_HOST", skynet.getenv "LOGIN_PORT")
local cms = string.format("%s:%s", skynet.getenv "CMS_HOST", skynet.getenv "CMS_PORT")
local mongo = string.format("%s:%s", skynet.getenv "CMS_HOST", skynet.getenv "CMS_PORT")
local mysql = string.format("%s:%s", skynet.getenv "CMS_HOST", skynet.getenv "CMS_PORT")
local redis = string.format("%s:%s", skynet.getenv "CMS_HOST", skynet.getenv "CMS_PORT")
local alert = skynet.getenv("ALERT_ENABLE") and "已开启" or "未开启"

return function()
    local info = require "bw.util.clusterinfo"
    local profile = info.profile
    return {
        online      = 0,
        run_time    = date_helper.format_now(),
        desc        = desc,
        clustername = clustername,
        pnet_addr   = info.pnet_addr or "未知",
        inet_addr   = info.inet_addr or "未知",
        pid         = info.pid or "未知",
        profile     = profile,
        gate        = gate,
        webconsole  = cms,
        mongo       = mongo,
        redis       = redis,
        mysql       = mysql,
        alert       = alert,
    }
end
