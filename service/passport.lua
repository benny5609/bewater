local skynet = require "skynet.manager"
local bewater   = require "util"
local uuid   = require "uuid"

local string_gsub = string.gsub
local uid2passport = {}
local passport2uid = {}

local CMD = {}
function CMD.create(uid)
    local passport = uid2passport[uid]
    if passport then
        passport2uid[passport] = nil
    end
    while true do
        passport = string_gsub(uuid(), '-', '')
        if not passport2uid[passport] then
            break
        end
    end
    uid2passport[uid] = passport
    passport2uid[passport] = uid
    return passport
end

function CMD.get_uid(passport)
    return passport2uid[passport]
end

function CMD.get_passport(uid)
    return uid2passport[uid]
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        bewater.ret(f(...))
    end)
    skynet.register "passport"
end)
