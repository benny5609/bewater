local class = require "bw.class"

local DEFAULT_MAX = 50

local mt = {}
function mt:ctor(rank_name, rank_type, max_count, asc)
    self.name = assert(rank_name)
    self.type = assert(rank_type)
    self.max_count = max_count or DEFAULT_MAX
end

return class(mt)
