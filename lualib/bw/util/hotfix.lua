local skynet    = require "skynet"
local sname     = require "bw.sname"

local M = {}
local function new_module(modname)
    skynet.cache.clear()
    local module = package.loaded[modname]
    if module then
        package.loaded[modname] = nil
    end
    local new_mod = require(modname)
    package.loaded[modname] = module
    return new_mod
end

local class_prop = {
    classname = true,
    class = true,
    Get = true,
    Set = true,
    super = true,
    __newindex = true,
    __index = true,
    new = true,
}

function M.class(modname)
    local old_class = require(modname)
    local new_class = new_module(modname)

    if old_class.classname and old_class.class then
        for k, v in pairs(new_class.class) do
            if not class_prop[k] then
                old_class[k] = v
            end
        end
    else
        for k, v in pairs(new_class) do
            old_class[k] = v
        end
    end
end

function M.module(modname)
    if not package.loaded[modname] then
        return require(modname)
    end
    local old_mod = require(modname)
    local new_mod = new_module(modname)

    for k,v in pairs(new_mod) do
        if type(v) == "function" then
            old_mod[k] = v
        end
    end
    return old_mod
end

-- 注册热更,由GM服务托管，需要处理hotfix这个消息
function M.reg()
    skynet.send(sname.GM, "lua", "reg_hotfix", skynet.self())
end

function M.unreg()
    skynet.send(sname.GM, "lua", "unreg_hotfix", skynet.self())
end

return M
