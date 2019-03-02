local bewater   = require "bw.bewater"
local util      = require "bw.util"
local class     = require "bw.class"
local mongo     = require "bw.db.mongo_helper"

local DEFAULT_MAX = 50

local mt = {}
function mt:ctor(rank_name, rank_type, max_count, cmp)
    self.name = assert(rank_name)
    self.type = assert(rank_type)
    self.max_count = max_count or DEFAULT_MAX
    self.cmp = cmp or function(a, b) return a > b end
    self.list = {}

    self:load()
end

function mt:init_by_data(data)
    data = data or {}
    self.list = data.list or {}
end

function mt:base_data()
    return {
        name = self.name,
        type = self.type,
        max_count = self.max_count,
        list = self.list
    }
end

function mt:load()
    local data = mongo.find_one("rank", {name = self.name}, {_id = false})
    if not data then
        data = self:base_data()
        mongo.insert("rank", data)
    end
    self:init_by_data(data)
end

function mt:save()
    mongo.update("rank", {name = self.name}, self:base_data())
end

function mt:find(k)
    for i, item in pairs(self.list) do
        if k == item.k then
            return item, i
        end
    end
end

function mt:update(k, v)
    local last = self.list[#self.list]
    if last and #self.list >= self.max_count then
        if not self.cmp(v, last.v) then
            return
        end
    end

    local old, i = self:find(k)
    if old then
        old.v = v
    else
        self.list[#self.list + 1] = bewater.protect {
            k = k,
            v = v
        }
    end

    for i = #self.list, 2, -1 do
        if self.cmp(self.list[i].v, self.list[i-1].v) then
            local item = self.list[i]
            self.list[i] = self.list[i-1]
            self.list[i-1] = item
        end
    end

    while #self.list > self.max_count do
        self.list[#self.list] = nil
    end

    self:save()
end

return class(mt)
