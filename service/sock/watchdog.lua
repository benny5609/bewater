local skynet = require "skynet"

local server, player = ...
assert(server) -- 服务器逻辑(xxx.xxxserver)
assert(player) -- 玩家逻辑(xxx.xxxplayer)

local server = require(server)

local CMD = {}
local SOCKET = {}
local gate
local fd2agent = {} -- socket对应的agent
local acc2agent = {} -- 每个账号对应的agent
local free_list = {} -- 空闲的agent list

local table_insert = table.insert
local table_remove = table.remove

local function pop_free_agent()
    local agent = free_list[#free_list]
    if agent == 0 then
        return skynet.newservice("sock/agent", player)
    end
    free_list[#free_list] = nil
    return agent
end

local function close_socket(fd)
 	skynet.call(gate, "lua", "kick", fd)
    fd2agent[fd] = nil   
end

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	fd2agent[fd] = pop_free_agent()
	skynet.call(fd2agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

function SOCKET.close(fd)
	print("socket close",fd)
    close_socket(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
    close_socket(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf, preload)
    preload = preload or 10     -- 预加载agent数量
	skynet.call(gate, "lua", "open" , conf)
    for i = 1, preload do
        local agent = skynet.newservice("sock/agent", player)
        table_insert(free_list, agent)
    end
end

-- 上线后agent绑定acc，下线缓存一段时间
function CMD.bind_acc(agent, acc)
    acc2agent[acc] = agent
end

-- 下线一段时间后调用
function CMD.free_agent(acc, agent)
    table_insert(free_list, agent) 
    acc2agent[acc] = nil
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
    
end)
