local skynet = require "skynet"
local _M = {}
local address

local function get_address()
	if not address then
		address = skynet.uniqservice "mail_mgr"
	end
	return address
end

skynet.init(
	function()
		get_address()
	end
)

function _M.poll(dt, ...)
	return skynet.call(".SYSEMAIL", "lua", "poll", dt)
end

function _M.get(id, ...)
	return skynet.call(".SYSEMAIL", "lua", "get", id)
end

function _M.call_init_rooms(...)
	local handle = get_address()
	return skynet.call(handle, "init_rooms", ...)
end

return _M
