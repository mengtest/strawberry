local base = require "room.components.base"

local function produce( ... )
	-- body
	local _M = {}
	_M.base = base()
	return _M
end

return produce