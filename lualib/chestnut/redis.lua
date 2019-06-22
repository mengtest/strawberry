local skynet = require "skynet"
local redis = require "skynet.db.redis"

local conf = {
	host = "127.0.0.1" ,
	port = 6379 ,
	db = 0
}

local _M = {}
-------------------------------------------------------------------------------string

function _M.append(self, key, value, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "append", key, value)
end

function _M.decr(self, key, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "decr", key)
end

function _M.decrby(self, key, decrement, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "decrby", key, decrement)
end

function _M.get(self, key, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "get", key)
end


function _M.incr(self, key, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "incr", key)
end

function _M.set(self, key, value, ... )
	-- body
	skynet.send(".redis", "lua", "set", "set", key, value)
end


-------------------------------------------------------------------------------hash

function _M.hdel(self, key, field, ... )
	-- body
	skynet.send(".redis", "lua", "set", "hdel", key, field)
end

function _M.hexists(self, key, field, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "hexists", key, field)
end

function _M.hget(self, key, field, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "hget", key, field)
end

function _M.hgetall(self, key, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "hgetall", key)
end

function _M.hset(self, key, field, value, ... )
	-- body
	skynet.send(".redis", "lua", "get", "hset", key, field, value)
end


-------------------------------------------------------------------------------sortedset

function _M.zadd(self, key, score, member, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "zadd", key, score, member)
end

function _M.zrang(self, key, start, stop, ... )
	-- body
	return skynet.call(".redis", "lua", "get", "zrang", key, start, stop)
end


return _M