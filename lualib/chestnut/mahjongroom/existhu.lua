local hutype = require "chestnut.mahjongroom.hutype"
local region = require "chestnut.mahjongroom.region"

local function exist(lo, ... )
	-- body
	local m = {}
	if lo == region.SICHUAN then
		m[hutype.PINGHU]          = true
		m[hutype.DUIDUIHU]        = true
		m[hutype.QINGYISE]        = true
		m[hutype.DAIYAOJIU]       = true
		m[hutype.QIDUI]           = true
		m[hutype.JINGOUDIAO]      = true
		m[hutype.QINGDUIDUI]      = true
		m[hutype.LONGQIDUI]       = true
		m[hutype.QINGQIDUI]       = true
		m[hutype.QINGYAOJIU]      = true
		m[hutype.JIANGJINGOUDIAO] = true
		m[hutype.QINGJINGOUDIAO]  = true
		m[hutype.TIANHU]          = true
		m[hutype.DIHU]            = true
		m[hutype.QINGLONGQIDUI]   = true
		m[hutype.SHIBALUOHAN]     = true
		m[hutype.QINGSHIBALUOHAN] = true
	elseif lo == region.SHANXI then
		m[hutype.PINGHU]          = true
		m[hutype.DUIDUIHU]        = true
		m[hutype.QINGYISE]        = true
		m[hutype.DAIYAOJIU]       = true
		m[hutype.QIDUI]           = true
		m[hutype.JINGOUDIAO]      = true
		m[hutype.QINGDUIDUI]      = true
		m[hutype.LONGQIDUI]       = true
		m[hutype.QINGQIDUI]       = true
		m[hutype.QINGYAOJIU]      = true
		m[hutype.JIANGJINGOUDIAO] = true
		m[hutype.QINGJINGOUDIAO]  = true
		m[hutype.TIANHU]          = true
		m[hutype.DIHU]            = true
		m[hutype.QINGLONGQIDUI]   = true
		m[hutype.SHIBALUOHAN]     = true
		m[hutype.QINGSHIBALUOHAN] = true
	end
	local function xx(hu, ... )
		-- body
		local res = m[hu]
		assert(res ~= nil)
		return res
	end
	return xx
end

return exist