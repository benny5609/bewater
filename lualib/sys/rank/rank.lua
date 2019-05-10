local class     = require "bw.class"
local mongo     = require "bw.db.mongo_helper"
local factory   = require "bw.orm.factory"
local util      = require "bw.util"
local log       = require "bw.log"

local trace = log.trace("rank")

local mt = {}
function mt:ctor(cmp)
    assert(type(cmp) == "function")
    self.cmp = cmp
    self.obj = nil
end

function mt:load(query)
    local data = mongo.find_one("rank", {name = query.name}, {_id = false})
    if not data then
        data = factory.create_obj("Rank", query)
        mongo.insert("rank", data)
    end
    self.obj = factory.create_obj("Rank", data)
end

function mt:save()
    local new_obj = factory.extract_data(self.obj)
    if util.cmp_table(new_obj, self.obj) then
        trace("no change, rank:%s", self.obj.name)
    end
    mongo.update("rank", {name = self.name}, self.obj)
    self.obj = new_obj
end

function mt:find(k)
    for i, item in pairs(self.obj.items) do
        if k == item.k then
            return item, i
        end
    end
end

function mt:update(k, v)
    local list = self.obj.items
    local last = list[#list]
    if last and #list >= self.obj.max_count then
        if not self.cmp(v, last.v) then
            return false
        end
    end

    local old = self:find(k)
    if old then
        old.v = v
    else
        list[#list + 1] = {
            k = k,
            v = v
        }
    end

    for i = #list, 2, -1 do
        if self.cmp(list[i].v, list[i-1].v) then
            local item = list[i]
            list[i] = list[i-1]
            list[i-1] = item
        end
    end

    while #list > self.obj.max_count do
        list[#list] = nil
    end
    return true
end

return class(mt)
