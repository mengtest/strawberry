log = {}
log.info = function ( ... )
	-- body
end
local opcode = require "opcode"
cc = {}
require "class"
class = cc.class

local gang = require "gang"
local hu = require "hu"
local card = require "card"
local cards = {
	card.new(card.type.CRAK, 5, 2),
	card.new(card.type.CRAK, 5, 3),

	card.new(card.type.CRAK, 6, 1),
	card.new(card.type.CRAK, 8, 2),
	card.new(card.type.DOT, 4, 2),
	card.new(card.type.DOT, 5, 2),
	card.new(card.type.DOT, 6, 2),
	card.new(card.type.DOT, 7, 2),
	card.new(card.type.DOT, 8, 2),
	card.new(card.type.DOT, 9, 2),
}

local putcards = {
	{hor = 1, cards = {
		card.new(card.type.CRAK, 3, 1),
		card.new(card.type.CRAK, 3, 2),
		card.new(card.type.CRAK, 3, 3),
	}},
}

print(hu.check_sichuan_jiao(cards, {}).code)

-- local code, c = gang(1, 1, card.new(card.type.CRAK, 6, 4), cards, {})
-- print(code)
-- if code ~= opcode.none then
-- 	print(c:get_value())
-- end

print("-----------------------------------------------------")

-- print(hu.check_sichuan(cards, {}))

-- local cards = {
-- 	card.new(card.type.CRAK, 1, 1),
-- 	card.new(card.type.CRAK, 1, 2),
-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 4, 1),
-- 	card.new(card.type.CRAK, 5, 1),
-- 	card.new(card.type.CRAK, 5, 2),
-- 	card.new(card.type.CRAK, 5, 3),
-- 	card.new(card.type.CRAK, 5, 4),
-- 	card.new(card.type.CRAK, 9, 1),
-- 	card.new(card.type.CRAK, 9, 2),
-- 	card.new(card.type.CRAK, 9, 3),
-- 	card.new(card.type.BAM, 5, 1),
-- 	card.new(card.type.BAM, 6, 1),
-- 	card.new(card.type.BAM, 7, 1),
-- }

-- print(hu.check_sichuan(cards, {}))

-- local cards = {
-- 	card.new(card.type.CRAK, 1, 1),
-- 	card.new(card.type.CRAK, 1, 2),
-- 	card.new(card.type.CRAK, 1, 3),

-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 4, 2),
-- 	card.new(card.type.CRAK, 5, 3),

-- 	card.new(card.type.CRAK, 9, 1),
-- 	card.new(card.type.CRAK, 9, 2),
-- 	card.new(card.type.CRAK, 9, 3),
-- 	card.new(card.type.BAM, 5, 1),
-- 	card.new(card.type.BAM, 6, 1),
-- 	card.new(card.type.BAM, 7, 1),
-- }

-- print(hu.check_sichuan(cards, {}))

-- local cards = {
-- 	card.new(card.type.CRAK, 1, 1),
-- 	card.new(card.type.CRAK, 1, 2),
-- 	card.new(card.type.CRAK, 1, 3),

-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 4, 2),
-- 	card.new(card.type.CRAK, 5, 3),
	
-- 	card.new(card.type.BAM, 5, 1),
-- 	card.new(card.type.BAM, 6, 1),
-- 	card.new(card.type.BAM, 7, 1),
-- }

-- local putcards = {
-- 	{hor = 1, cards = {
-- 		card.new(card.type.CRAK, 9, 1),
-- 		card.new(card.type.CRAK, 9, 2),
-- 		card.new(card.type.CRAK, 9, 3),
-- 		card.new(card.type.CRAK, 9, 4),
-- 	}},
-- }

-- print(hu.check_sichuan(cards, putcards))

-- local cards = {
-- 	card.new(card.type.CRAK, 1, 1),
-- 	card.new(card.type.CRAK, 1, 2),
-- 	card.new(card.type.CRAK, 1, 3),
-- 	card.new(card.type.CRAK, 1, 4),

-- 	card.new(card.type.CRAK, 3, 1),
-- 	card.new(card.type.CRAK, 3, 1),

-- 	card.new(card.type.CRAK, 5, 2),
-- 	card.new(card.type.CRAK, 5, 3),
	
-- 	card.new(card.type.BAM, 5, 1),
-- 	card.new(card.type.BAM, 5, 2),

-- 	card.new(card.type.BAM, 7, 1),
-- 	card.new(card.type.BAM, 7, 2),

-- 	card.new(card.type.BAM, 9, 1),
-- 	card.new(card.type.BAM, 9, 2),
-- }

-- print(hu.check_sichuan(cards, {}))

-- local cards = {
-- 	card.new(card.type.CRAK, 1, 1),
-- 	card.new(card.type.CRAK, 1, 2),

-- 	card.new(card.type.CRAK, 2, 1),
-- 	card.new(card.type.CRAK, 2, 2),
-- 	card.new(card.type.CRAK, 2, 3)
-- }

-- local putcards = {
-- 	{hor = 1, cards = {
-- 		card.new(card.type.CRAK, 9, 1),
-- 		card.new(card.type.CRAK, 9, 2),
-- 		card.new(card.type.CRAK, 9, 3),
-- 	}},
-- 	{hor = 1, cards = {
-- 		card.new(card.type.CRAK, 2, 1),
-- 		card.new(card.type.CRAK, 2, 2),
-- 		card.new(card.type.CRAK, 2, 3),
-- 	}},
-- 	{hor = 1, cards = {
-- 		card.new(card.type.BAM, 9, 1),
-- 		card.new(card.type.BAM, 9, 2),
-- 		card.new(card.type.BAM, 9, 3),
-- 	}},
-- }

-- print(hu.check_sichuan(cards, putcards))