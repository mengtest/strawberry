local gangmultiple = require "chestnut.mahjongroom.gangmultiple"
local humultiple = require "chestnut.mahjongroom.humultiple"
local _M = {}

function _M.look_hu(jiao, hu, ... )
	-- body
	local hm = assert(m[hu])
	if jiao == jiaotype.DIANGANGHUA then
		hm = hm * 2
	elseif jiao == jiaotype.GANGSHANGPAO then
		hm = hm * 2
	elseif jiao == jiaotype.QIANGGANGHU then
		hm = hm * 2
	elseif jiao == jiaotype.ZIGANGHUA then
		hm = hm * 2
	elseif jiao == jiaotype.ZIMO then
		hm = hm * 2
	end
	if hm == hutype.PINGHU then
		if gang > 0 then
			hm = hm * gang * 2
		end
	end	
	return hm
end

function _M.look_gang(gangtype, ... )
	-- body
	if gangmultiple[gangtype] then
		return gangmultiple[gangtype] 
	else
		error('gangtype not found', gangtype)
	end
end

return _M