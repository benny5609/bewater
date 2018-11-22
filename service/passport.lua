local Skynet = require "skynet.manager"
local Util   = require "util"
local Uuid   = require "uuid"

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
        passport = string_gsub(Uuid(), '-', '')
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

Skynet.start(function()
    Skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        Util.ret(f(...))
    end)
    Skynet.register "passport"
end)
