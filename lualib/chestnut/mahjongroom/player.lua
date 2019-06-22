local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local util = require "common.utils"
local card = require "chestnut.mahjongroom.card"
local group = require "chestnut.mahjongroom.group"
local region = require "chestnut.mahjongroom.region"
local opcode = require "chestnut.mahjongroom.opcode"
local gang = require "chestnut.mahjongroom.gang"
local gangtype = require "chestnut.mahjongroom.gangtype"
local hu = require "chestnut.mahjongroom.hu"
local jiaotype = require "chestnut.mahjongroom.jiaotype"
local hutype = require "chestnut.mahjongroom.hutype"


local state = {}
state.NONE       = 0
state.ENTER      = 1
state.WAIT_READY = 2
state.READY      = 3
state.WAIT_SHUFFLE = 4
state.SHUFFLE    = 5
state.WAIT_DICE  = 6
state.DICE       = 7
state.WAIT_XUANPAO = 8
state.XUAN_PAO   = 9
state.WAIT_TAKE_XUANQUE = 10
state.TAKE_XUANQUE = 11
state.WAIT_XUANQUE = 12
state.XUANQUE    = 13
state.WAIT_DEAL  = 14
state.DEAL       = 15
state.WAIT_TAKECARD = 16
state.TAKECARD   = 17
state.WAIT_TURN  = 18
-- state.TURN       = 15   -- 此状态可能不会出现
state.WAIT_LEAD  = 19
state.LEAD       = 20

state.MCALL      = 21
state.OCALL      = 22
state.WAIT_PENG  = 23
state.PENG       = 24
state.WAIT_GANG  = 25
state.GANG       = 26
state.WAIT_HU    = 27
state.HU         = 28

state.WAIT_OVER  = 29
state.OVER       = 30
state.WAIT_SETTLE  = 31
state.SETTLE       = 32
state.WAIT_RESTART = 33
-- state.RESTART    = 27

local cls = class("player")

cls.state = state

function cls:ctor(env, uid, agent)
	-- body
	assert(env and uid and agent)
	self._env    = env
	self._uid    = uid
	self._idx    = 0      -- players index
	self._agent  = agent  -- agent
	self._name   = ""
	self._sex    = 0      -- 0 nv
	self._chip   = 1000
	self._fen    = 0
	self._online = false  -- user in game
	self._robot  = false  -- user

	self._state  = state.NONE
	self._laststate = state.NONE
	self._que    = 0
	self._takecardsidx = 1
	self._takecardscnt = 0
	self._takecardslen = 0
	self._takecards = {}

	-- play
	self._cards  = {}
	self._colorcards = {}
	self._leadcards = {}
	self._putcards = {}
	self._putidx   = 0
	self._holdcard = nil
	self._hucards = {}

	self._cancelcd = nil
	self._chipli = {}   -- { code,dian,chip}

	return self
end

function cls:get_uid( ... )
	-- body
	return self._uid
end

function cls:set_uid(value, ... )
	-- body
	self._uid = value
end

function cls:get_agent( ... )
	-- body
	return self._agent
end

function cls:set_agent(agent, ... )
	-- body
	self._agent = agent
end

function cls:get_idx( ... )
	-- body
	return self._idx
end

function cls:get_online()
	-- body
	return self._online
end

function cls:set_online(value)
	-- body
	self._online = value
end

function cls:set_robot(flag, ... )
	-- body
	self._robot = flag
end

function cls:get_robot( ... )
	-- body
	return self._robot
end

function cls:get_noone( ... )
	-- body
	return (self._uid == 0)
end

function cls:set_noone(value, ... )
	-- body
	self._uid = 0
end

function cls:set_name(name, ... )
	-- body
	self._name = name
end

function cls:get_name( ... )
	-- body
	return self._name
end

function cls:get_chip( ... )
	-- body
	return self._chip
end

function cls:set_chip(value) 
	self._chip = value
end

function cls:get_sex( ... )
	-- body
	return self._sex
end

function cls:set_sex(value, ... )
	-- body
	self._sex = value
end

function cls:get_fen( ... )
	-- body
	return self._fen
end

function cls:set_fen(value, ... )
	-- body
	self._fen = value
end

function cls:get_que( ... )
	-- body
	return self._que
end

function cls:set_que(value, ... )
	-- body
	self._que = value
	log.info("player idx : %d", self._idx)
	local len = #self._cards
	for i=1,len do
		self._cards[i]:set_que(self._que)
	end
	self:sort_cards()

	log.info("player %d set_que", self._idx)
	self:print_cards()
end

function cls:set_state(s, ... )
	-- body
	self._state = s
end

function cls:get_state( ... )
	-- body
	return self._state
end

function cls:get_cards( ... )
	-- body
	return self._cards
end

function cls:get_cards_value( ... )
	-- body
	local cards = {}
	for i,card in ipairs(self._cards) do
		local v = card:get_value()
		cards[i] = v
	end
	return cards
end

function cls:hashu( ... )
	-- body
	return self._hashu
end

function cls:clear( ... )
	-- body
	self._hashu  = false

	self._fen    = 0
	self._que    = 0

	self._takecardsidx = 1
	self._takecardscnt = 0
	self._takecardslen = 0
	self._takecards = {}

	self._cards  = {}
	self._leadcards = {}
	self._putcards = {}
	self._holdcard = nil
	self._hucards = {}

	self._cancelcd = nil
	self._chipli = {}
end

function cls:print_cards( ... )
	-- body
	log.info("player %d begin print cards", self._idx)
	local len = #self._cards
	for i=1,len do
		log.info(self._cards[i]:describe())
	end
	log.info("player %d end print cards", self._idx)
end

-- 处理takecards相关------------------------------------------------------------------------------
function cls:take_card( ... )
	-- body
	if self._takecardscnt > 0 then
		if self._takecardsidx > self._takecardslen then
			self._takecardsidx = 1
			return false
		end

		local card = self._takecards[self._takecardsidx]
		self._takecards[self._takecardsidx] = nil
		self._takecardsidx = self._takecardsidx + 1
		self._takecardscnt = self._takecardscnt - 1

		log.info("player %d been taken card", self._idx)
		return true, card
	else
		return false
	end
end

function cls:insert_take_cards_with_pos( ... )
	-- body
end

function cls:pack_takecards()
	-- body
	local ccs = {}
	for _,card in pairs(self._takecards) do
		local cc = { pos = card:get_pos(), value = card:get_value() }
		table.insert(ccs, cc)
	end
	return ccs
end

-- 处理cards in hand------------------------------------------------------------------
function cls:_quicksort(low, high, ... )
	-- body
	if low >= high then
		return
	end
	local first = low
	local last  = high
	local key = self._cards[first]
	while first < last do
		while first < last do
			if self._cards[last]:mt(key) then
				last = last - 1
			else
				self._cards[first] = self._cards[last]
				self._cards[first]:set_pos(first)
				break
			end
		end
		while first < last do
			if not self._cards[first]:mt(key) then
				first = first + 1
			else
				self._cards[last] = self._cards[first]
				self._cards[last]:set_pos(last)
				break
			end
		end
	end
	self._cards[first] = key
	self._cards[first]:set_pos(first)
	self:_quicksort(low, first-1)
	self:_quicksort(first+1, high)   
end

function cls:sort_cards( ... )
	-- body
	self:_quicksort(1, #self._cards)
end

function cls:insert(card, ... )
	-- body
	assert(card)
	local len = #self._cards
	for i=1,len do
		if self._cards[i]:mt(card) then
			for j=len,i,-1 do
				self._cards[j + 1] = self._cards[j]
				self._cards[j + 1]:set_pos(j + 1)
			end
			self._cards[i] = card
			self._cards[i]:set_pos(i)
			return i
		end
	end
	self._cards[len+1] = card
	self._cards[len+1]:set_pos(len + 1)
	return len + 1
end

function cls:insert_with_pos(card, ... )
	-- body
end

function cls:remove(card, ... )
	-- body
	return self:remove_pos(card._pos)
end

function cls:remove_pos(pos, ... )
	-- body
	log.info("remove pos %d", pos)
	local len = #self._cards
	if pos >= 1 and pos <= len then
		local card = self._cards[pos]
		if pos < len then
			for i=pos,len-1 do
				self._cards[i] = self._cards[i + 1]
				self._cards[i]:set_pos(i)
			end
		else
			assert(len == pos)
		end
		self._cards[len] = nil
		return card
	else
		log.info("remove cards at pos %d is wrong.", pos)
	end
end

function cls:find(c, ... )
	-- body
	local len = #self._cards
	local low = 1
	local high = len
	while low <= high do 
		if self._cards[low]:get_value() == c then
			return self._cards[low]
		end
		if self._cards[high]:get_value() == c then
			return self._cards[high]
		end
		local mid = math.tointeger((high + low) / 2)
		if self._cards[mid]:get_value() == c then
			return self._cards[mid]
		end
		if self._cards[mid]:get_value() < c then
			low = mid + 1
		else
			high = mid - 1
		end
	end
	return nil
end

function cls:pack_cards()
	-- body
	local ccs = {}
	for _,card in pairs(self._cards) do
		local cc = { pos = card:get_pos(), value = card:get_value() }
		table.insert(ccs, cc)
	end
	return ccs
end

-- end ------------------------------------------------------------------------------------

-- 开始处理出牌
function cls:append_lead(card, ... )
	-- body
	assert(card)
	table.insert(self._leadcards, card)
	local len = #self._leadcards
	card:set_pos(len)
	card:set_que(card.type.NONE)
end

function cls:remove_lead_tail(card, ... )
	-- body
	assert(card)
	local len = #self._leadcards
	assert(self._leadcards[len]:get_value() == card:get_value())
	self._leadcards[len] = nil
end

function cls:lead(c, isHoldcard, ... )
	-- body
	assert(self._state == state.WAIT_TURN)
	assert(c)
	if isHoldcard then
		if self._holdcard:get_value() == c then
			local card = self._holdcard
			self:append_lead(card)
			self._holdcard = nil
			return true, card
		else
			return false
		end
	else
		local card
		local len = #self._cards
		for i=1,len do
			if self._cards[i]:get_value() == c then
				card = self._cards[i]
				self:append_lead(card)
				self:remove(card)

				assert(self._holdcard)
				if self._holdcard then
					self:insert(self._holdcard)
					self._holdcard = nil
				end
				break
			end
		end
		if card then
			self:print_cards()
			return true, card
		else
			return false
		end
	end
end

function cls:pack_leadcards()
	-- body
	local ccs = {}
	for _,card in pairs(self._leadcards) do
		local cc = { pos = card:get_pos(), value = card:get_value() }
		table.insert(ccs, cc)
	end
	return ccs
end

function cls:pack_putcards( ... )
	-- body
end

function cls:pack_holdcard()
	-- body
	if self._holdcard then
		return { pos = self._holdcard:get_pos(), value = self._holdcard:get_value() }
	else
		return { pos = 0, value = 0 }
	end
end

function cls:pack_hucards()
	-- body
	local ccs = {}
	for _,card in pairs(self._hucards) do
		local cc = { pos = card:get_pos(), value = card:get_value() }
		table.insert(ccs, cc)
	end
	return ccs
end

-----------------------------------------------------------------------------------end
-- na
function cls:take_turn_card(card, ... )
	-- body
	assert(self._holdcard == nil)
	self._holdcard = card
	self._holdcard:set_que(self._que)
end

-- hu
function cls:check_que( ... )
	-- body
	local res = true
	if self._env._local == region.Sichuan then
		local se = 1
		local ctype = self._cards[1]:tof()
		local len = #self._cards
		for i=2,len do
			if self._cards[i]:tof() ~= ctype then
				se = se + 1
				ctype = self._cards[i]:tof()
			end
		end
		if se > 2 then
			res = false
		end
	end
	return res
end

function cls:check_jiao( ... )
	-- body
	log.info("player %d check jiao", self._idx)
	self:print_cards()
	local res = hu.check_sichuan_jiao(self._cards, self._putcards)
	return res
end

function cls:check_hu(hint, card, jiao, dian, ... )
	-- body
	assert(card and jiao and who)
	self._hu = {}
	self._hu.idx = self._idx
	self._hu.card = card
	self._hu.code = hutype.NONE
	self._hu.gang = 0
	self._hu.jiao = jiao
	self._hu.dian = who

	if self._env._local == region.Sichuan then
		if card:tof() == self._que then
			return self._hu
		end
	end
	
	if not self:check_que() then
		self._hu.code = hutype.NONE
		return self._hu
	end

	local pos = self:insert(card)
	assert(pos ~= 0)
	self:print_cards()

	local res = hu.check_sichuan_hu(self._cards, self._putcards)
	if res.code ~= hutype.NONE then
		self._hu.code = res.code
		self._hu.gang = res.gang
	else
		self._hu.code = hutype.NONE
		self._hu.gang = 0
	end
	self:remove_pos(pos)

	return self._hu
end

function cls:hu(info, last, lastcard, ... )
	-- body
	log.info("player %d hu", self._idx)
	log.info("info idx:%d, card:%d, code:%d, jiao:%d, dian:%d", info.idx, info.card, info.code, info.jiao, info.dian)
	log.info("self idx:%d, card:%d, code:%d, jiao:%d, dian:%d", self._hu.idx, self._hu.card:get_value(), self._hu.code, self._hu.jiao, self._hu.dian)
	assert(info and last and lastcard)
	assert(info.idx == self._idx)
	assert(info.card == self._hu.card:get_value())
	assert(info.code == self._hu.code)
	assert(info.gang == self._hu.gang)
	assert(info.jiao == self._hu.jiao)
	assert(info.dian == self._hu.dian)
	self._state = state.HU
	self._hashu = true
	if self._hu.jiao == jiaotype.ZIMO or
		self._hu.jiao == jiaotype.DIANGANGHUA or
		self._hu.jiao == jiaotype.ZIGANGHUA then
		assert(self._holdcard == self._hu.card)
		table.insert(self._hucards, self._holdcard)
	elseif self._hu.jiao == jiaotype.QIANGGANGHU then
		local card = self._env._players[self._hu.dian]:qianggang(self._hu.card)
		assert(card)
		table.insert(self._hucards, card)
	else
		assert(lastcard == self._hu.card)
		last:remove_lead_tail(lastcard)
		table.insert(self._hucards, lastcard)
	end
	self:print_cards()
	table.insert(self._hucards, self._hu.card)
	return self._hu
end

-- gang
function cls:check_gang(card, dianPlayer, ... )
	-- body
	assert(card and dianPlayer)
	local gang = {}
	gang.idx = self._idx
	gang.code = opcode.none
	gang.card = card
	gang.dianPlayer = dianPlayer
	gang.gangtype = gangtype.none

	if self._env._local == region.Sichuan then
		if card:tof() == self._que then
			return gang
		end
	end
	self:print_cards()

	local res = gang.check_gang(self._idx, dianPlayer, card, self._cards, self._putcards)
	if res.code == opcode.gang then
		gang.gangtype = res.gangtype
		gang.card = res.card
		if gang.card == card then
			gang.isHoldcard = true
		end
		return gang
	end
	return gang
end

function cls:check_xueliu_gang(card, dianPlayer, ... )
	-- body
	assert(card and who)
	local gang = {}
	gang.idx = self._idx
	gang.code = opcode.none
	gang.card = card
	gang.dianPlayer = dianPlayer
	gang.gangtype = gangtype.none

	if self._env._local == region.Sichuan then
		if card:tof() == self._que then
			return gang
		end
	end
	
	self:print_cards()

	local res = gang.check_xueliu_gang(self._idx, dianPlayer, card, self._cards, self._putcards)
	if res.code == opcode.gang then
		gang.code = res.code
		gang.gangtype = res.gangtype
		gang.card = res.card

		return gang
	end

	return self._gang
end

function cls:gang(gangtype, lastPlayer, lastCard, ... )
	-- body
	log.info("player %d gang card: %s", self._idx, lastCard:describe())
	if gangtype == opcode.zhigang then
		local cards = {}
		local len = #self._cards
		for i=1,len do
			if self._cards[i]:eq(self._gang.card) then
				table.insert(cards, self._cards[i])
			end
			if #cards == 3 then
				break
			end
		end
		assert(#cards == 3)
		
		for i,v in ipairs(cards) do
			self:remove(v)
		end

		last:remove_lead_tail(lastCard)
		table.insert(cards, lastCard)
		assert(#cards == 4)
		
		local pgcards = {}
		pgcards.cards = cards
		pgcards.hor   = math.random(0, 3)
		pgcards.code  = opcode.gang
		pgcards.gangtype = gangtype.zhigang
		table.insert(self._putcards, pgcards)
		self._putidx = #self._putcards
		self:print_cards()
		return pgcards
	elseif gangtype == opcode.angang then
		
		if self._holdcard:eq(lastCard) then
			local cards = {}
			local len = #self._cards
			for i=1,len do
				if self._cards[i]:eq(lastCard) then
					table.insert(cards, self._cards[i])
				end
				if #cards == 3 then
					break
				end
			end
			assert(#cards == 3)
			for i,v in ipairs(cards) do
				self:remove(v)
			end
			
			table.insert(cards, self._holdcard)
			self._holdcard = nil
			assert(#cards == 4)

			local pgcards = {}
			pgcards.cards = cards
			pgcards.hor   = math.random(0, 3)
			pgcards.code  = opcode.gang
			pgcards.gangtype = gangtype
			table.insert(self._putcards, pgcards)
			self._putidx = #self._putcards
			self:print_cards()
			return pgcards
		else
			local cards = {}
			local idx = 0
			local len = #self._cards
			for i=1,len do
				if self._cards[i]:eq(lastCard) then
					table.insert(cards, self._cards[i])
					idx = i
				end
				if #cards == 4 then
					break
				end
			end
			assert(#cards == 4)
			for i,v in ipairs(cards) do
				self:remove(v)
			end

			local pgcards = {}
			pgcards.cards = cards
			pgcards.hor   = math.random(0, 3)
			pgcards.code  = opcode.gang
			pgcards.gangtype = gangtype
			table.insert(self._putcards, pgcards)
			self._putidx = #self._putcards
			self:print_cards()
			return pgcards
		end
	elseif info.code == opcode.bugang then
		assert(#self._putcards > 0)
		for i,v in ipairs(self._putcards) do
			if v.code == opcode.peng and v.cards[1]:eq(lastCard) then
				v.code = opcode.bugang
				table.insert(v.cards, lastCard)
				if lastCard == self._holdcard then
					self._holdcard = nil
				else
					self:remove(lastCard)
				end
				return v
			end
		end
	else
		assert(false)
	end
end

function cls:qianggang(card, ... )
	-- body
	for i,v in ipairs(self._putcards) do
		if v.code == opcode.bugang and #v.cards == 4 then
			if v.cards[4]:get_value() == card:get_value() then
				v.code = opcode.peng
				v.cards[4] = nil
				return card
			end
		end
	end
	return
end

-- peng
function cls:check_peng(card, dianPlayer, ... )
	-- body
	assert(card and dian)
	local peng = {}
	peng.idx  = self._idx
	peng.code = opcode.none
	peng.card = card
	peng.dianPlayer = dianPlayer

	if self._env._local == region.Sichuan then
		if card:tof() == self._que then
			return peng
		end
	end
	
	local count = 0
	local len = #self._cards
	for i=1,len do
		if self._cards[i]:eq(card) then
			count = count + 1
		end
		if count == 2 then
			break
		end
	end
	
	if count == 2 then
		self._peng.code = opcode.peng
	end
	return peng
end

function cls:peng(lastPlayer, lastCard, ... )
	-- body
	assert(self._state == state.OCALL)
	
	local cards = {}
	local len = #self._cards
	for i,v in ipairs(self._cards) do
		if v:eq(lastCard) then
			table.insert(cards, v)
		end
		if #cards == 2 then
			break
		end
	end
	assert(#cards == 2)
	for i,v in ipairs(cards) do
		self:remove(v)
	end
	
	lastPlayer:remove_lead_tail(lastCard)
	table.insert(cards, lastCard)
	assert(#cards == 3)

	local pgcards = {}
	pgcards.cards = cards
	pgcards.hor   = math.random(0, 2)
	pgcards.code  = opcode.peng
	table.insert(self._putcards, pgcards)
	self:print_cards()
	return pgcards
end

function cls:take_turn_after_peng( ... )
	-- body
	log.info("take_turn_after_peng")
	self:print_cards()
	local len = #self._cards
	local card = self:remove_pos(len)
	assert(card)
	self._holdcard = card
	return card
end

function cls:timeout(ti, ... )
	-- body
	self._cancelcd = util.set_timeout(ti, function ( ... )
		-- body
		return
		
		-- if self._state == state.WAIT_TURN then
		-- 	assert(self._holdcard)
		-- 	self._env:lead(self._idx, self._holdcard:get_value())
		-- elseif self._state == state.MCALL then
		-- 	local args = {}
		-- 	args.idx = self._idx
		-- 	args.opcode = opcode.guo
		-- 	self._env:timeout_call(args)
		-- elseif self._state == state.OCALL then
		-- 	local args = {}
		-- 	args.idx = self._idx
		-- 	args.opcode = opcode.guo
		-- 	self._env:timeout_call(args)
		-- elseif self._state == state.WAIT_TAKE_XUANQUE then
		-- 	local args = {}
		-- 	args.idx = self._idx
		-- 	args.que = card.type.DOT
		-- 	self._env:timeout_xuanque(args)
		-- end
	end)
	assert(self._cancelcd)
end

function cls:cancel_timeout( ... )
	-- body
	self._cancelcd()
end

-- restart
function cls:take_restart( ... )
	-- body
	self:clear()
end

function cls:settle(chip, ... )
	-- body
	self._chip = self._chip + chip
	return self._chip
end

function cls:record_settle(node, ... )
	-- body
	table.insert(self._chipli, node)
end

-- tuisui
function cls:tuisui(settle, ... )
	-- body
	local len = #self._chipli
	for i=1,len do
		local v = self._chipli[i]
		if v.chip > 0 and v.win[1] == v.idx and v.gang == opcode.zhigang or v.gang == opcode.angang or v.gang == opcode.bugang then
			local lose_len = #v.lose
			local xchip = v.chip / lose_len
			for kk,vv in pairs(v.lose) do
				local item = {}
				item.idx  = vv
				item.chip = xchip
				item.left = self._env._players[item.idx]:settle(item.chip)

				item.win  = v.lose
				item.lose = v.win

				item.gang   = v.gang
				item.hucode = v.hucode
				item.hujiao = v.hujiao
				item.hugang = v.hugang
				item.huazhu = v.huazhu
				item.dajiao = v.dajiao
				item.tuisui = 1
				self._env:insert_settle(settle, item.idx, item)
				self._env._players[v]:record_settle(item)				
			end
		end

		local litem = {}
		litem.idx  = v.idx
		litem.chip = -v.chip
		litem.left = self._env._players[litem.idx]:settle(litem.chip)

		litem.win  = v.lose
		litem.lose = v.win

		litem.gang = v.gang
		litem.hucode = v.hucode
		litem.hujiao = v.hujiao
		litem.hugang = v.hugang
		litem.huazhu = v.huazhu
		litem.dajiao = v.dajiao
		litem.tuisui = 1

		self._env:insert_settle(settle, item.idx, item)
		self._env._players[v]:record_settle(item)
	end
end

function cls:tuisui_with_qianggang(settle, ... )
	-- body
	local len = #self._chipli
	assert(len > 0)
	local base_settle = self._chipli[len]
	assert(base_settle.gang == opcode.bugang)
	local lose_len = #base_settle.lose
	local xchip = base_settle.chip / lose_len
	for i=1,lose_len do
		local idx = base_settle.lose[i]
		local p = self._env._players[idx]

		local item = {}
		item.idx  = idx
		item.chip = xchip
		item.left = self._env._players[item.idx]:settle(item.chip)

		item.win  = base_settle.lose
		item.lose = base_settle.win

		item.gang   = base_settle.gang
		item.hucode = base_settle.hucode
		item.hujiao = base_settle.hujiao
		item.hugang = base_settle.hugang
		item.huazhu = base_settle.huazhu
		item.dajiao = base_settle.dajiao
		item.tuisui = 1

		self._env:insert_settle(settle, item.idx, item)
		self._env._players[idx]:record_settle(item)
	end

	local item = {}
	item.idx  = base_settle.idx
	item.chip = -base_settle.chip
	item.left = self._env._players[item.idx]:settle(item.chip)

	item.win  = base_settle.lose
	item.lose = base_settle.win

	item.gang   = base_settle.gang
	item.hucode = base_settle.hucode
	item.hujiao = base_settle.hujiao
	item.hugang = base_settle.hugang
	item.huazhu = base_settle.huazhu
	item.dajiao = base_settle.dajiao
	item.tuisui = 1
	
	self._env:insert_settle(settle, item.idx, item)
	self:record_settle(item)
end

return cls