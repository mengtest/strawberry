local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local redis = require "skynet.db.redis"

local pcall = skynet.pcall
local assert = assert
local table = table
local string = string

local mode = ...

if mode == "agent" then

local function connect_redis()
	--skynet.fork( watching, conf )
	local host = skynet.getenv "cache_host"
	local port = skynet.getenv "cache_port"
	local db   = skynet.getenv "cache_db"
	local c = {
		host = host or "192.168.1.116",
		port = port or 6379,
		db = db or 0
	}
	return redis.connect(c)	
end	

local function disconnect_redis( ... )
	-- body
	if cache then
		cache:disconnect()
	end
end

skynet.start(function()
	local db = connect_redis()
	skynet.dispatch("lua", function (_,_, mode, cmd, ...)
		local f = db[cmd]
		local r = f(db, ... )
		if mode == "get" then
			skynet.retpack(r)
		end
	end)
end)

else

skynet.start(function()
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	skynet.dispatch("lua", function (_, source, mode, cmd, ...)
		if mode == "get" then
			local r = skynet.call(agent[balance], "lua", mode, cmd, ...)
			skynet.retpack(r)
		else
			skynet.send(agent[balance], "lua", mode, cmd, ...)
		end
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
	skynet.register ".redis"
end)

end
