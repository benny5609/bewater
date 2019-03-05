local keywords = {
    ['__data'] = true,
}

local function parse_boolean(_, s)
    return s == true
end

local function parse_number(_, s)
    local v = assert(tonumber(s), s)
    return v
end

local function parse_string(_, s)
    return tostring(s)
end

local function parse_struct(cls, data)
    local obj = setmetatable({__data={}}, cls.mt)
    for k in pairs(cls.attrs) do
        -- trigger struct_setfield
        local k_data = data and data[k] or nil
        obj[k] = k_data
    end
    return obj
end

local function parse_list(cls, data)
    local obj = setmetatable({__data={}}, cls.mt)
    if data then
        assert(type(data)=='table',cls.name)
        for i, item in ipairs(data) do
            -- trigger list_setfield
            obj[i] = item
        end
    end
    return obj
end

local function parse_map(cls, data)
    local obj = setmetatable({__data={}}, cls.mt)
    if data then
        assert(type(data)=='table',cls.name)
        for k,v in pairs(data) do
            -- trigger map_setfield
            obj[k] = v
        end
    end
    return obj
end

local list_mt = {
    __index = function(t,k)
        return t.__data[k]
    end,
    __len = function(t)
        return #t.__data
    end,
    __pairs = function(t)
        return next, t.__data, nil
    end,
    __next = function(old_next, t, index)
        return old_next(t.__data, index)
    end,
}

local table_mt = {
    __index = function(t,k)
        return t.__data[k]
    end,
    __pairs = function(t)
        return next, t.__data, nil
    end,
    __next = function(old_next, t, index)
        return old_next(t.__data, index)
    end,
}

local types = {
    boolean = {is_atom=true,  parser=parse_boolean, default=false},
    number  = {is_atom=true,  parser=parse_number,  default=0},
    string  = {is_atom=true,  parser=parse_string,  default=""},
    struct  = {is_atom=false, parser=parse_struct,  default=nil},
    list    = {is_atom=false, parser=parse_list,    default=nil},
    map     = {is_atom=false, parser=parse_map,     default=nil},
}

local cls_map = nil

local create_cls

-- struct
local function struct_setfield(obj, k, v)
    -- 适配mongo _id
    if k == "_id" then
        rawset(obj.__data, k, v)
        return
    end

    local mt = getmetatable(obj)
    local cls = mt.__cls

    local v_cls = cls.attrs[k]
    if not v_cls then
        error(string.format('cls<%s> has no attr<%s>', cls.name, k))
    end

    local v_mt = getmetatable(v)
    if type(v) == "table" and v_mt == v_cls.mt then
        rawset(obj.__data, k, v)
        return
    end

    if v == nil and v_cls.is_atom then
        rawset(obj.__data, k, v_cls.default)
    else
        rawset(obj.__data, k, v_cls:new(v))
    end
end

local function create_struct_cls(cls, parent)
    assert(not parent, cls.name)
    assert(cls.name, "struct no name")
    assert(cls.attrs, "struct no attrs")

    cls.mt.__newindex = struct_setfield

    local attrs = {}
    for k,v in pairs(cls.attrs) do
        if keywords[k] then
            error(string.format("class<%s> define key attr<%s>", cls.name, k))
        end
        v.name = k
        attrs[k] = create_cls(v, cls.name)
    end
    cls.attrs = attrs
    return cls
end

-- list
local function list_setfield(obj, k, v)
    local mt = getmetatable(obj)
    local cls = mt.__cls

    if k ~= math.tointeger(k) then
        error(string.format('cls<%s> key<%s> is not integer', cls.name, k))
    end

    local v_cls = cls.item
    local v_mt = getmetatable(v)
    if type(v) == "table" and v_mt then
        if v_mt == v_cls.mt then
            rawset(obj.__data, k, v)
            return
        end
        error(string.format('cls<%s.%s> value type not match',cls.name, k))
    end

    if v == nil then
        rawset(obj.__data, k, nil)
    else
        rawset(obj.__data, k, v_cls:new(v))
    end
end

local function create_list_cls(cls)
    cls.mt.__newindex = list_setfield
    cls.item = create_cls(cls.item)
    return cls
end

-- map
local function map_setfield(obj, k, v)
    -- 适配mongo _id
    if k == "_id" then
        rawset(obj.__data, k, v)
        return
    end

    local mt = getmetatable(obj)
    local cls = mt.__cls

    local k_data = cls.key:new(k)
    if v == nil then
        rawset(obj.__data, k_data, nil)
        return
    end

    local v_cls = cls.value
    local v_mt = getmetatable(v)
    if type(v) == "table" and v_mt then
        if v_mt == v_cls.mt then
            rawset(obj.__data, k, v)
            return
        end
        error(string.format('obj<%s.%s> value type not match',cls.name, k_data))
    end

    rawset(obj.__data, k_data, v_cls:new(v))
end

local function create_map_cls(cls)
    cls.mt.__newindex = map_setfield
    cls.key = create_cls(cls.key)
    assert(cls.key.is_atom)
    cls.value = create_cls(cls.value)
    return cls
end

function create_cls(cls, parent)
    local data_type = cls.type

    if parent then
        cls.name = string.format("%s.%s", parent, cls.name)
    end

    -- is a user defined struct type
    local ref_cls = cls_map[data_type]
    if ref_cls then
        for k,v in pairs(ref_cls) do
            if k ~= "name" then
                cls[k] = v
            end
        end
        return cls
    end

    local tt = assert(types[data_type], data_type)
    cls.is_atom = tt.is_atom
    cls.new     = tt.parser
    cls.default = tt.default

    -- is a atom type
    if cls.is_atom then
        return cls
    end

    cls.mt = {
        __cls = cls,
    }

    if data_type == 'list' then
        for k,v in pairs(list_mt) do
            cls.mt[k] = v
        end
    else
        for k,v in pairs(table_mt) do
            cls.mt[k] = v
        end
    end
    if data_type == 'struct' then
        create_struct_cls(cls, parent)
    elseif data_type == 'list' then
        create_list_cls(cls, parent)
    elseif data_type == 'map' then
        create_map_cls(cls, parent)
    else
        assert(nil, "unknown data type: "..data_type)
    end
    return cls
end

local M = {}
function M.get_cls_map()
    return cls_map
end

function M.init(type_list)
    cls_map = {}
    for _, item in ipairs(type_list) do
        assert(item.name)
        cls_map[item.name] = create_cls(item)
    end
end

function M.create(cls_name, data)
    local cls = assert(cls_map[cls_name], cls_name)
    return cls:new(data)
end
return M
