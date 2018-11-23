-- Http 请求 get post
--
local Skynet    = require "skynet"
local Sname     = require "sname"
require "bash"

local M = {}
function M.get(url, get, header, no_reply)
    if no_reply then
        return Skynet.send(Sname.WEB, "lua", "request", url, get, nil, header, no_reply)
    else
        return Skynet.call(Sname.WEB, "lua", "request", url, get, nil, header, no_reply)
    end
end

function M.post(url, post, header, no_reply)
    --Skynet.error("http post:", url, post)
    if no_reply then
        return Skynet.send(Sname.WEB, "lua", "request", url, nil, post, header, no_reply)
    else
        return Skynet.call(Sname.WEB, "lua", "request", url, nil, post, header, no_reply)
    end
end

function M.url_encoding(tbl, encode)
    local data = {}
    for k, v in pairs(tbl) do
        table.insert(data, string.format("%s=%s", k, v))
    end

    local url = table.concat(data, "&")
    if encode then
        return string.gsub(url, "([^A-Za-z0-9])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    else
        return url
    end
end

return M
