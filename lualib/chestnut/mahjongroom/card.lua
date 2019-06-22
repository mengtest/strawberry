-- local log = require "log"
local assert = assert

local TYPE_SHIFT = 8
local NUM_SHIFT = 4
local IDX_SHIFT = 0

local cls = class("card")

cls.type = {}
cls.type.NONE = 0
cls.type.CRAK = 1       -- 万
cls.type.BAM  = 2       -- 条
cls.type.DOT  = 3       -- 同

function cls:ctor(t, num, idx)
	-- body
	-- log.info("t:%d, num:%d, idx:%d", t, num, idx)
	assert(t and num and idx)
	self._type = t
	self._num  = num
	self._idx  = idx
	self._value = ((t & 0xff) << TYPE_SHIFT) | ((num & 0x0f) << NUM_SHIFT) | ((idx & 0x0f) << IDX_SHIFT)
	self._color = 0
	self._pos = 0
	self._que  = 0
	self._master = false  -- 判断是否已经被分配
	self._bright = false  -- 判断是否已经被选中

	self:_init_color()
	return self
end

function cls:_init_color()
	-- body
	if self._type == cls.type.CRAK then
		self._color = self._num
	elseif self._type == cls.type.DOT then
		self._color = 9 + self._num
	elseif self._type == cls.type.BAM then
		self._color = 18 + self._num
	end
end

function cls:tof()
	-- body
	return self._type
end

function cls:nof()
	-- body
	return self._num
end

function cls:iof( ... )
	-- body
	return self._idx
end

function cls:get_value( ... )
	-- body
	return self._value
end

function cls:get_color( ... )
	-- body
	return self._color
end

function cls:set_que(ctype, ... )
	-- body
	if self._type == ctype then
		self._que = 1
	else
		self._que = 0
	end
end

function cls:get_que( ... )
	-- body
	return self._que
end

-- position
function cls:get_pos( ... )
	-- body
	return self._pos
end

function cls:set_pos(pos, ... )
	-- body
	self._pos = pos
end

function cls:set_master(m, ... )
	-- body
	self._master = m
end

function cls:get_master( ... )
	-- body
	return self._master
end

function cls:set_bright(flag, ... )
	-- body
	self._bright = flag
end

function cls:get_bright( ... )
	-- body
	return self._bright
end

function cls:clear( ... )
	-- body
	self._que = 0
	self._pos = 0         -- deal 
	self._master = false  -- deal
	self._bright = false  -- selection
end

-- 比较单牌,这里只比较数字
function cls:mt(o, ... )
	-- body
	if self._que == o._que then
		return self._value > o._value
	else
		return self._que > o._que
	end
end

function cls:eq(o, ... )
	-- body
	if self._type == o._type and self._num == o._num then
		return true
	else
		return false
	end
end

function cls:lt(o, ... )
	-- body
	return self._value < o._value
end

function cls:describe( ... )
	-- body
	local res = ""
	if self._type == cls.type.CRAK then
		res = res .. "crak "
	elseif self._type == cls.type.BAM then
		res = res .. "bam "
	elseif self._type == cls.type.DOT then
		res = res .. "dot "
	end

	res = res .. string.format("%d,", self._num)
	res = res .. string.format("pos: %d", self._pos)

	return res
end

return cls