local skynet = require "skynet"
local _M = {}

function _M.board( ... )
	-- body
	return skynet.call(".RADIOCENTER", "lua", "board")
end

function _M.adver( ... )
	-- body
	return skynet.call(".RADIOCENTER", "lua", "adver")
end

return _M
