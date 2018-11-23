local Skynet = require "skynet"
local Sname = require "sname"

local M = {}
function M.add_gmcmd(modname, gmcmd_path)
    Skynet.call(Sname.GM, "lua", "add_gmcmd", modname, gmcmd_path)
end

function M.run(...)
    return Skynet.call(Sname.GM, "lua", "run", ...)
end
return M
