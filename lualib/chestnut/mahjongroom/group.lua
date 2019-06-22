local log = require "chestnut.skynet.log"
local card = require "chestnut.mahjongroom.card"
local assert = assert

local kind = {}
kind.NONE   = 0
kind.SINGLE = 1
kind.COUPLE = 2
-- 顺子
kind.STRAIGHT = 3 
-- 炸弹
kind.BOMB = 4
-- 
kind.COUPLE_STRAIGHT = 5
-- 
kind.IDENTICAL3 = 6
kind.IDENTICAL3_SINGLE = 7
kind.IDENTICAL3_COUPLE = 8

kind.KINGANDQ = 9

local cls = class("group")

cls.kind = kind

function cls:ctor(cards, ... )
	-- body
	assert(cards)
	self._cards = cards
	local k = self:_parse(cards)
	self._kind = k
end

function cls:_parse(cards, ... )
	-- body
	-- 假定出牌的时候就已经排序了，这里就不用排序,倒序（越来越小）
	-- 分析大小，然后决定
	local sz = #cards
	if sz == 1 then
		return kind.SINGLE
	elseif sz == 2 then
		if cards[1]:eq(cards[2]) then
			return kind.COUPLE
		elseif cards[1]:tof() == 5 and
			cards[2]:tof() == 4 then
			return kind.KINGANDQ
		else
			return kind.NONE
		end
	elseif sz == 3 then
		if cards[1]:eq(cards[2]) and cards[1]:eq(cards[3]) then
			return kind.IDENTICAL3
		else
			return kind.NONE
		end
	elseif sz == 4 then
		if cards[1]:eq(cards[2]) then
			-- 两种可能
			if cards[1]:eq(cards[3]) then
				if cards[1]:eq(cards[4]) then
					return kind.BOMB
				else
					return kind.IDENTICAL3_SINGLE
				end
			else
				return kind.NONE
			end
 		else
 			if cards[2]:eq(cards[3]) and
 			 	cards[2]:eq(cards[4]) then
 				return kind.IDENTICAL3_SINGLE
 			else
 				return kind.NONE
 			end
		end
	elseif sz == 5 then
		if cards[1]:eq(cards[2]) then
			if cards[1]:eq(cards[3]) then
				if cards[4]:eq(cards[5]) then
					return kind.IDENTICAL3_COUPLE 
				else
					return kind.NONE
				end
			else
				if cards[3]:eq(cards[4]) and
				 	cards[3]:eq(cards[5]) then
					return kind.IDENTICAL3_COUPLE
				else
					return kind.NONE
				end
			end
		else
			if cards[1]:nof() == cards[2]:nof() + 1 and
				cards[2]:nof() == cards[3]:nof() + 1 and
			 	cards[3]:nof() == cards[4]:nof() + 1 and
				cards[4]:nof() == cards[5]:nof() + 1 then
				return kind.STRAIGHT
			else
				return kind.NONE
			end
		end
	elseif sz >= 6 then
		if cards[1]:eq(cards[2]) then
			if sz % 2 == 0 then
				for i=1,sz,2 do
					if cards[i]:eq(cards[i+1]) then
					else
						return kind.NONE
					end
				end
				return kind.COUPLE_STRAIGHT
			else
				return kind.NONE
			end
		else
			for i=1,sz-1 do
				if cards[i]:nof() == cards[i+1]:nof() + 1 then
				else
					return kind.NONE
				end
			end
			return kind.STRAIGHT
		end
	else
		return kind.NONE
	end
end

function cls:get_kind( ... )
	-- body
	return self._kind
end

function cls:get_cards( ... )
	-- body
	return self._cards
end

function cls:check_kind(other, ... )
	-- body
	if self._kind == other._kind and
		self._kind ~= kind.NONE then
		return true
	else
		log.info("self kind: %d, other kind: %d", self._kind, other._kind)
		return false
	end
end

function cls:mt(other, ... )
	-- body
	assert(self:check_kind(other))
	if self._kind == kind.SINGLE or self._kind == kind.COUPLE then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		return v1:mt(v2)
	elseif self._kind == kind.STRAIGHT then
		assert(#self._cards == #other._cards)
		local v1 = self._cards[#self._cards]
		local v2 = other._cards[#other._cards]
		return v1:mt(v2)
	elseif self._kind == kind.BOMB then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		return v1:mt(v2)
	elseif self._kind == kind.COUPLE_STRAIGHT then
		local v1 = self._cards[#self._cards]
		local v2 = self._cards[#self._cards]
		return v1:mt(v2)
	elseif self._kind == kind.IDENTICAL3 then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		return v1:mt(v2)
	elseif self._kind == kind.IDENTICAL3_SINGLE then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		if v1:eq(v2) then
			local v3 = self._cards[4]
			local v4 = other._cards[4]
			return v3:mt(v4)
		else
			return v1:mt(v2)
		end
	elseif self._kind == kind.IDENTICAL3_COUPLE then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		if v1:eq(v2) then
			local v3 = self._cards[4]
			local v4 = other._cards[4]
			return v3:mt(v4)
		else
			return v1:mt(v2)
		end
	elseif self._kind == kind.KINGANDQ then	
		return true
	else
		return false
	end
end

function cls:eq(other, ... )
	-- body
	assert(self:check_kind(other))
	if self._kind == kind.SINGLE or self._kind == kind.COUPLE then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		if v1:eq(v2) then
			return true
		else
			return false
		end
	elseif self._kind == kind.STRAIGHT then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		if v1:eq(v2) then
			return true
		else
			return false
		end
	elseif self._kind == kind.BOMB then	
		return false
	elseif self._kind == kind.COUPLE_STRAIGHT then
		local v1 = self._cards[1]
		local v2 = other._cards[1]
		if v1:eq(v2) then
			return true
		else
			return false
		end
	elseif self._kind == kind.IDENTICAL3 then
		return false
	elseif self._kind == kind.IDENTICAL3_SINGLE then
		return false
	elseif self._kind == kind.IDENTICAL3_COUPLE then	
		return false
	end
end

function cls:lt(other, ... )
	-- body
	assert(self:check_kind(other))
	if not self:mt(other) or not self:eq(other) then
		return true
	else
		return false
	end
end

return cls