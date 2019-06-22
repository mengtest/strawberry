-- local log = require "log"
local assert = assert
local comp_num = require "comp_num"

local TYPE_SHIFT = 8
local NUM_SHIFT = 4
local IDX_SHIFT = 0

local cls = class("card")

cls.type = {}
cls.type.NONE = 0
cls.type.CLUBS    = 1       -- 梅花
cls.type.DIANMOND = 2       -- 方块
cls.type.HEART    = 3       -- 红心
cls.type.SPADE    = 4       -- 黑桃

function cls:ctor(t, num, idx)
	-- body
	-- log.info("t:%d, num:%d, idx:%d", t, num, idx)
	assert(t and num)
	self.type = t
	self.num  = num
	self.idx  = 0
	self.value = ((t & 0xff) << TYPE_SHIFT) | ((num & 0x0f) << NUM_SHIFT) | ((idx & 0x0f) << IDX_SHIFT)
	self.pos = 0
	return self
end

function cls:clear()
	-- body
	assert(self)
end

-- 比较单牌
function cls:mt(o)
	-- body
	if self.num == o.num then
		return self.type - o.type
	else
		return comp_num.mt(self.num, o.num)
	end
end

function cls:lt(o)
	-- body
	return not self:mt(o)
end

function cls:describe()
	-- body
	local res = ""
	if self.type == cls.type.CLUBS then
		res = res .. "clubs "
	elseif self.type == cls.type.DIANMOND then
		res = res .. "dianmond "
	elseif self.type == cls.type.HEART then
		res = res .. "heart "
	elseif self.type == cls.type.SPADE then
		res = res .. "spade "
	end

	res = res .. string.format("%d,", self.num)
	res = res .. string.format("pos: %d", self.pos)

	return res
end

return cls