local class     = require "bw.class"
local factory   = require "bw.orm.factory"
local util      = require "bw.util"
local log       = require "bw.log"
local mongo     = require "db.mongo"

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
    local cur_obj = factory.extract_data(self.obj)
    if self.last_obj and util.cmp_table(cur_obj, self.last_obj) then
        log.debugf("no change, rank:%s", self.obj.name)
        return
    end
    mongo.update("rank", {name = self.obj.name}, self.obj)
    log.debug("save", self.obj.name)
    self.last_obj = cur_obj
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
