local skynet = require "skynet"
local _M = {}

function _M.poll(dt, ... )
	-- body
	return skynet.call(".SYSEMAIL", "lua", "poll", dt)
end

function _M.get(id, ... )
	-- body
	return skynet.call(".SYSEMAIL", "lua", "get", id)
end

return _M