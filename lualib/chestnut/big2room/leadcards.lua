
local leadtype = require('lead_type')
local comp_num = require('comp_num')
local array = require('chestnut.array')
local assert = assert

local cls = class('leadcards')

function cls:ctor(type, cards)
	-- body
	self.leadtype = type
	self.cards = cards            -- sortedvector
	self.seqMap = array(13)()     -- 按照数字的排序  num ==> cnt
	self.colMap = array(4)()     -- 按照类型的排序  type ==> cnt
	self.numMap = {}             --
	self:init_cards(self.cards)
end

function cls:init_cards(arr)
	-- body
	assert(self)
	for _,v in ipairs(arr) do
		if self.seqMap[v.num] then
			self.seqMap[v.num] = self.seqMap[v.num] + 1
		else
			self.seqMap[v.num] = 1
		end
		if self.colMap[v.type] then
			self.colMap[v.type] = self.colMap[v.type] + 1
		else
			self.colMap[v.type] = 1
		end
	end
	for k,v in pairs(self.seqMap) do
		if v then
			if v >= 2 then
				self.numMap[v] = k
			end
		end
	end
end

function cls:mt(o)
	-- body
	if self.leadtype == o.leadtype then
		if self.leadtype == leadtype.SINGLE or
			self.leadtype == leadtype.COUPLE then
			return self.cards[1]:mt(o.cards[1])
		elseif self.leadtype == leadtype.SHUNZI or
			self.leadtype == leadtype.TONGHUASHUN or
			self.leadtype == leadtype.TONGHUA then
			return self.cards[5]:mt(o.cards[5])
		elseif self.leadtype == leadtype.HULU then
			local mNum = self.numMap[3]
			local oNum = self.numMap[3]
			return comp_num.mt(mNum, oNum)
		elseif self.leadtype == leadtype then
			local mNum = self.numMap[4]
			local oNum = self.numMap[4]
			return comp_num.mt(mNum, oNum)
		end
	else
		return self.leadtype - o.leadtype
	end
end

return cls