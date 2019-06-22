local skynet = require "skynet"
local _M = {}

function _M.cache_select(key, ... )
	-- body
	skynet.call("DBMONITOR", "lua", "cache_select", key, ...)
end

function _M.cache_update(key, ... )
	-- body
	skynet.send("DBMONITOR", "lua", "cache_update", key, ...)
end

function _M.cache_insert(key, ... )
	-- body
	skynet.send("DBMONITOR", "lua", "cache_insert", key, ...)
end

return _M