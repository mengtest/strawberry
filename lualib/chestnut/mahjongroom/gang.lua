local opcode = require "chestnut.mahjongroom.opcode"
local gangtype = require "chestnut.mahjongroom.gangtype"

local function check_gang_card_p(first, last, cards, ... )
	-- body
	local len = #cards
	local pos = first:get_pos()
	local pre = pos - 1
	if pre >= 1 then
		if cards[pre]:tof() == first:tof() then
			if cards[pre]:nof() + 1 == first:nof() then
				return false
			end
		end
	end
	pos = last:get_pos()
	local nxt = pos + 1
	if nxt <= len then
		if cards[nxt]:tof() == last:tof() then
			if last:nof() + 1 == cards[nxt]:nof() then
				return false
			end
		end
	end
	return true
end

local _M = {}

function _M.check_gang(idx, dianPlayer, card, cards, putcards, ... )
	-- body
	local res = {}
	res.code = opcode.none
	res.gangtype = gangtype.none
	res.card = card

	if dianPlayer:get_idx() == idx then

		if #putcards > 0 then
			for i,v in ipairs(putcards) do
				if #v.cards == 3 then
					if v.cards[1]:eq(card) then
						res.code = opcode.gang
						res.gangtype = gangtype.bugang
						res.card = card
						return res
					end
				end
			end
		end

		-- an for card
		local len = #cards
		local first = cards[1]
		local count = 1
		for i=2,len do
			if cards[i]:eq(first) then
				count = count + 1
			elseif count == 3 then
				if first:eq(card) then					
					res.code = opcode.gang
					res.gangtype = gangtype.angang
					res.card = card
					return res
				else
					first = cards[i]
					count = 1
				end
			else
				first = cards[i]
				count = 1
			end
		end
		if count == 3 then
			if first:eq(card) then
				res.code = opcode.gang
				res.gangtype = gangtype.angang
				res.card = card
				return res
			end
		end

		-- an for had
		first = cards[1]
		count = 1
		for i=2,len do
			if cards[i]:eq(first) then
				count = count + 1
			elseif count == 4 then
				res.code = opcode.gang
				res.gangtype = gangtype.angang
				res.card = first
				return res
			else
				first = cards[i]
				count = 1
			end
		end
		if count == 4 then
			res.code = opcode.gang
			res.gangtype = gangtype.angang
			res.card = first
			return res
		end

		-- bu for had
		if #putcards > 0 then
			for i,v in ipairs(putcards) do
				if #v.cards == 3 then
					-- find in cards
					for j,xcard in ipairs(cards) do
						if v.cards[1]:eq(xcard) then
							res.code = opcode.gang
							res.gangtype = gangtype.bugang
							res.card = xcard
							return res
						end
					end
				end
			end
		end

		return res
	else
		local len = #cards
		local first = cards[1]
		local count = 1
		for i=2,len do
			if cards[i]:eq(first) then
				count = count + 1
			elseif count == 3 then
				if first:eq(card) then
					res.code = opcode.gang
					res.gangtype = gangtype.zhigang
					res.card = card
					return res
				else
					first = cards[i]
					count = 1
				end
			else
				first = cards[i]
				count = 1
			end
		end
		if count == 3 then
			if first:eq(card) then
				res.code = opcode.gang
				res.gangtype = gangtype.zhigang
				res.gang = card
				return res
			end
		end
		return res
	end
end

function _M.check_xueliu_gang(idx, curidx, card, cards, putcards, ... )
	-- body
	assert(idx and curidx and card and cards and putcards)
	local res = {}
	res.code = opcode.none
	res.card = card

	if curidx == idx then
		if #putcards > 0 then
			for i,v in ipairs(putcards) do
				if #v.cards == 3 then
					if v.cards[1]:eq(card) then
						res.code = opcode.bugang
						res.card = card
						return res
					end
				end
			end
		end

		-- an for card
		local len = #cards
		local first = cards[1]
		local count = 1
		for i=2,len do
			if cards[i]:eq(first) then
				count = count + 1
			elseif count == 3 then
				if first:eq(card) then
					local pos = first:get_pos()
					if check_gang_card_p(first, cards[pos+2], cards) then
						res.code = opcode.angang
						res.card = card
						return res
					end
					return res
				else
					first = cards[i]
					count = 1
				end
			else
				first = cards[i]
				count = 1
			end
		end
		if count == 3 then
			if first:eq(card) then
				local pos = first:get_pos()
				if check_gang_card_p(first, cards[pos+2], cards) then
					res.code = opcode.angang
					res.card = card
					return res
				end
			end
		end
		return res
	else
		local len = #cards
		local first = cards[1]
		local count = 1
		for i=2,len do
			if cards[i]:eq(first) then
				count = count + 1
			elseif count == 3 then
				if first:eq(card) then
					local pos = first:get_pos()
					if check_gang_card_p(first, cards[pos+2], cards) then
						res.code = opcode.angang
						res.card = card
						return res
					end
				else
					first = cards[i]
					count = 1
				end
			else
				first = cards[i]
				count = 1
			end
		end
		if count == 3 then
			if first:eq(card) then
				local pos = first:get_pos()
				if check_gang_card_p(first, cards[pos+2], cards) then
					res.code = opcode.angang
					res.card = card
					return res
				end
			end
		end
		return res
	end
end

return _M