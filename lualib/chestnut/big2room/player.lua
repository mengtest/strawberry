local log = require "chestnut.skynet.log"
local utils = require "chestnut.time_utils"
local vector = require "chestnut.sortedvector"
local fsm = require "chestnut.fsm"
local assert = assert

local state = {}
state.NONE           = "none"
state.INITDB         = "initdb"
state.WAIT_JOIN      = "wait_join"
state.JOIN           = "join"
state.WAIT_READY     = "wait_ready"
state.READY          = "ready"
state.WAIT_SHUFFLE   = "wait_shuffle"
state.SHUFFLE        = "shuffle"
state.WAIT_DEAL      = "wait_deal"      -- 以上状态都没有用
state.DEAL       	 = "deal"
state.WATCH          = "watch"          -- 观看状态，此时没有关于他的事物
state.WAIT_TURN      = "wait_turn"      -- 轮到你做出选择
-- state.TURN       = 15   -- 此状态可能不会出现
state.WAIT_CALL      = "wait_call"
state.CALL           = "call"
state.WAIT_OVER      = "wait_over"
state.OVER           = "over"
state.WAIT_SETTLE    = "wait_settle"
state.SETTLE         = "settle"
state.WAIT_RESTART   = "wait_restart"
-- state.RESTART    = 27

local cls = class("player")

cls.state = state

function cls:ctor(env, uid, agent)
	-- body
	assert(env and uid and agent)
	self.env    = env
	self.uid    = uid
	self.idx    = 0      -- players index
	self.agent  = agent  -- agent
	self.name   = ""
	self.sex    = 0      -- 0 nv
	self.chip   = 1000
	self.fen    = 0
	self.online = false  -- user in game
	self.robot  = false  -- user

	-- play
	self.cards  = vector(function (l, r)
		-- body
		return l:mt(r)
	end)()
	self.opcode = 0
	self.leadcards = nil
	self.timer = nil

	self.alert = nil
	self:init_alert(state.NONE)
	return self
end

function cls:is_none()
	-- body
	return (self.uid == 0)
end

function cls:clear()
	-- body
	self.cards  = vector()
	self.colorcards = {}
end

------------------------------------------
-- 初始状态机
function cls:init_alert(initial_state)
	-- body
	local alert = fsm.create({
		initial = initial_state,
		events = {
			{name = "ev_wait_join",     from = state.NONE,           to = state.WAIT_JOIN},
		    {name = "ev_join",          from = state.WAIT_JOIN,      to = state.JOIN},
		    {name = "ev_wait_ready",    from = state.NONE,           to = state.WAIT_READY},
		    {name = "ev_ready",         from = state.WAIT_READY,     to = state.READY},
		    {name = "ev_wait_deal",     from = state.JOIN,          to = state.WAIT_DEAL},
		    {name = "ev_deal",          from = state.WAIT_DEAL,      to = state.DEAL},
		    {name = "ev_watch_after_deal",         from = state.DEAL,    to = state.WATCH},
		    {name = "ev_watch_after_call",         from = state.CALL,    to = state.WATCH},
		    {name = "ev_wait_turn_after_deal",     from = state.DEAL,    to = state.WAIT_TURN},
		    {name = "ev_wait_turn_after_call",     from = state.CALL,    to = state.WAIT_TURN},

		    {name = "ev_wait_call_after_watch",         from = state.WATCH,        to = state.WAIT_CALL},
		    {name = "ev_wait_call_after_wait_turn",     from = state.WAIT_TURN,    to = state.WAIT_CALL},

		    {name = "ev_call",             from = state.WAIT_CALL,    to = state.CALL},
		    {name = "ev_wait_over",        from = state.CALL,         to = state.WAIT_OVER},
		    {name = "ev_over",             from = state.WAIT_OVER,    to = state.OVER},
		    {name = "ev_settle",           from = state.OVER,         to = state.SETTLE},
		    {name = "ev_restart",          from = state.SETTLE,       to = state.RESTART},

		    {name = "ev_reset_wait_deal",       from = "*",    to = state.WAIT_DEAL},
		    {name = "ev_reset_deal",            from = "*",    to = state.DEAL},
		    {name = "ev_reset_watch",           from = "*",    to = state.WATCH},
		    {name = "ev_reset_wait_turn",       from = "*",    to = state.WAIT_TURN},
		    {name = "ev_reset_wait_lead",       from = "*",    to = state.WAIT_LEAD},
		    {name = "ev_reset_lead",            from = "*",    to = state.LEAD},
		    {name = "ev_reset_wait_call",       from = "*",    to = state.WAIT_CALL},
		    {name = "ev_reset_call",            from = "*",    to = state.CALL},
		    {name = "ev_reset_wait_over",       from = "*",    to = state.WAIT_OVER},
		    {name = "ev_reset_over",            from = "*",    to = state.OVER},
		},
		callbacks = {
			on_join = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    on_ready = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    on_deal = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    on_lead = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    on_call = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    on_over = function(self, event, from, to, obj, msg) assert(obj) obj:on_state(event, from, to, msg) end,
		    -- on_clear = function(self, event, from, to, msg) print('phew... ' .. msg) end
		}
	})
	self.alert = alert
end

function cls:on_state(event, from, to)
	-- body
	-- assert(event and from and to)
	if to == state.JOIN then
		log.info('player join')
		self.env:on_next_state()
	elseif to == state.READY then
		self.env:on_next_state()
	elseif to == state.SHUFFLE then
	elseif to == state.WAIT_DEAL then
		self.timer = utils.set_timeout(100 * 40, function ()
			-- body
			self:timeout_deal()
		end)
	elseif to == state.DEAL then
		if self.timer then
			self.timer()
			self.timer = nil
		end
		self.env:on_next_state()
	elseif to == state.WAIT_TURN then
		self.timer = utils.set_timeout(100 * 40, function ()
			-- body
			self:timeout_turn()
		end)
	elseif to == state.WAIT_CALL then
		self.timer = utils.set_timeout(100 * 40, function ()
			-- body
			self:timeout_ca()
		end)
	elseif to == state.CALL then
		if self.timer then
			self.timer()
			self.timer = nil
		end
		self.env:on_next_state()
	elseif to == state.OVER then
		self.env:on_next_state()
	end
end

------------------------------------------
-- 发牌的时候直接插入
function cls:insert(card)
	-- body
	assert(card)
	self.cards:push(card)
end

function cls:remove(card)
	-- body
	return self:erase(card)
end

function cls:pack_cards()
	-- body
	local ccs = {}
	for _,card in pairs(self.cards) do
		local cc = { pos = card.pos, value = card.value }
		table.insert(ccs, cc)
	end
	return ccs
end

function cls:print_cards()
	-- body
	log.info("player %d begin print cards", self.idx)
	local len = #self.cards
	for i=1,len do
		log.info(self.cards[i]:describe())
	end
	log.info("player %d end print cards", self.idx)
end

-- end
------------------------------------------

------------------------------------------
-- 开始处理出牌
function cls:call(opcode)
	-- body
	assert(self.alert.is(state.WAIT_TURN))
	self.opcode = opcode
	if self.timer then
		self.timer()
		self.timer = nil
	end
end

function cls:lead(opcode, leadcards)
	-- body
	assert(self.alert.is(state.WAIT_TURN))
	-- 删除cards从self.cards
	self.opcode = opcode
	for i,v in ipairs(leadcards.cards) do
		self.cards:erase(v)
	end
	self.leadcards = leadcards
	if self.timer then
		self.timer()
		self.timer = nil
	end
	return 0
end

function cls:pack_leadcards()
	-- body
	local res = {}
	if self.leadcards then
		res.leadtype = assert(self.leadcards.leadtype)
		local ccs = {}
		for _,card in pairs(self.leadcards.cards) do
			local cc = { pos = card.pos, value = card.value }
			table.insert(ccs, cc)
		end
		res.cards = ccs
	end
	return res
end

-- 开始处理出牌over
------------------------------------------

------------------------------------------
-- 超时处理
function cls:timeout_deal()
	-- body
	log.info('timeout_deal %d step', self.idx)
	self.timer = nil
	self.env:step(self.idx, true)
end

function cls:timeout_turn()
	-- body
	self.timer = nil
	assert(self)
end

function cls:timeout_call()
	-- body
	log.info('timeout_deal %d call', self.idx)
	self.timer = nil
	self.env:step(self.idx, true)
end

function cls:timeout_over()
	-- body
	self.timer = nil
	self.env:step(self.idx, true)
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


return cls