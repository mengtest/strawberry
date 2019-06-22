
local function produce( ... )
	-- body
	local _M = {}

	_M.uid = nil
	_M.session = nil
	_M.udphost = nil
	_M.udpport = nil
	_M.udpgate = nil

	return _M
end

return produce