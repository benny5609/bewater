local uuid      = require "bw.uuid"

local string_gsub = string.gsub
local uid2passport = {}
local passport2uid = {}

local M = {}
function M.create(uid)
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

function M.get_uid(passport)
    return passport2uid[passport]
end

function M.get_passport(uid)
    return uid2passport[uid] or M.create(uid)
end

return M
