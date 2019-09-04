local skynet = require "skynet"
local mc = require "skynet.multicast"
-- local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local servicecode = require "chestnut.servicecode"
local fsm = require "chestnut.fsm"
local opcode = require "opcode"
local leadtype = require "lead_type"
local Card = require "card"
local Player = require "player"
local traceback = debug.traceback
local leadcards = require "leadcards"
local to_lead_type = require "to_lead_type"

local state = {}
state.NONE       = "none"      -- 最初的状态
state.INITDB     = "initdb"
state.START      = "start"
state.CREATE     = "create"
state.JOIN       = "join"      -- 此状态下会等待玩家加入
state.READY      = "ready"     -- 此状态下等待玩家准备
state.SHUFFLE    = "shuffle"   -- 此状态下洗牌
state.DEAL       = "deal"      -- 此状态发牌        (deprecated)
state.FIRSTTURN  = "firstturn" -- 第一个人出牌
state.TURN       = "turn"      -- 轮谁出牌          (麻将只是可以多人同时turn call)
state.CALL       = "call"      -- 只有pass命令
state.OVER       = "over"      -- 结束
state.SETTLE     = "settle"    -- 结算
state.RESTART    = "restart"   -- 重新开始
state.ROOMOVER   = 'roomover'

local MOCK = false

local cls = class("RoomContext")

function cls:ctor()
	-- body

	-- players
	self.players = {}
	for i=1,4 do
		local tmp = Player.new(self, 0, 0)
		tmp.idx = i
		self.players[i] = tmp
	end

	-- 房间数据
	self.channel = nil
	self.channelSubscribed = false
	self.id = 0
	self.open = false
	self.host = nil
	self.max = 4          -- 玩家数
	self.joined = 0
	self.online = 0
	self.maxju = 0        -- 玩的局数
	self.uplayers = {}

	-- play
	self._cards = {}         -- 洗牌
	self._cardssz = 52
	self._kcards = {}
	self:init_cards()

	self.firstidx = 0           -- 拿牌头家
	self.previdx = 0            -- 上一个玩家出牌
	self.curidx = 0             -- 玩家索引，当前轮到谁
	self.alert = self:create_alert(state.NONE)
	self.alert.ev_join(self)
	self.settles = {}           -- 在结束的时候已经完成

	-- 记录所有数据
	self._stime = 0
	self._record = {}

	return self
end

function cls:set_id(value)
	-- body
	self.id = value
end

function cls:clear()
	-- body
	self._countdown = 20 -- s

	self._state = state.NONE
	self._lastfirsthu  = 0    -- last,make next zhuangjia

	self._lastidx  = 0    -- last time lead from who
	self._lastcard = nil    -- last time lead card

	self._firsttake = 0
	self._firstidx  = 0    -- zhuangjia
	self._curtake   = 0
	self._curidx    = 0      -- player
	self._curcard = nil

	self._takeround = 1
	self._takepoint = 0

	self._call = {}
	self._callcounter = 0
end

function cls:find_noone()
	-- body
	if self.joined >= self.max then
		return nil
	end
	for i=1,self.max do
		if self.players[i].uid == 0 then
			return self.players[i]
		end
	end
end

function cls:get_player_by_uid(uid)
	-- body
	assert(uid)
	return self.uplayers[uid]
end

function cls:init_cards()
	-- body
	for i=1,4 do
		for j=1,13 do
			local cc = Card.new(i, j, 0)
			table.insert(self._cards, cc)         -- 用于洗牌
			self._kcards[cc.value] = cc           -- 用于查找
		end
	end
end

function cls:push_client(name, args)
	-- body
	for i=1,self.max do
		local p = self.players[i]
		if not p:is_none() then
			if p.online then
				log.info("push protocol %s to idx %d.", name, i)
				skynet.send(p.agent, "lua", name, args)
			end
		end
	end
end

function cls:push_client_idx(idx, name, args)
	-- body
	assert(idx and name and args)
	local p = self.players[idx]
	if not p:is_none() and p.online then
		log.info("push protocol %s to idx %d.", name, idx)
		skynet.send(p.agent, "lua", name, args)
	end
end

function cls:push_client_except_idx(idx, name, args)
	-- body
	for i=1,self.max do
		if idx ~= i then
			local p = self.players[i]
			if not p:is_none() and p.online then
				log.info("push protocol %s to idx %d.", name, i)
				skynet.send(p.agent, "lua", name, args)
			end
		end
	end
end

function cls:record(protocol, args, ... )
	-- body
	local tnode = {}
	tnode.protocol = protocol
	tnode.pt = (skynet.now() - self._stime)
	tnode.args = args
	table.insert(self._record, tnode)
end

-- 此函数只检测不同地方玩法的由胡的人数觉定是否结束
function cls:check_over()
	-- body
	if self.alert.is(state.LEAD) then
		local p = self.players[self.turn]
		if #p.cards == 0 then
			self:take_over()
		end
	end
end

function cls:check_roomover()
	-- body
	local ok = skynet.call('.ROOM_MGR', 'lua', 'room_check_nextju', self.id)
	if not ok then
		self.alert.ev_roomover(self)
	end
end

-- 所有玩家都转移状态
function cls:emit_player_event(event)
	-- body
	for i=1,self.max do
		local p = assert(self.players[i])
		p.alert[event](p)
	end
end

-- 创建状态机
function cls:create_alert(initial_state)
	-- body
	assert(self)
	local alert = fsm.create({
		initial = initial_state,
		events = {
			{name = "ev_start",        from = state.NONE,    to = state.START},
		    {name = "ev_join",         from = state.NONE,    to = state.JOIN},
		    {name = "ev_ready",        from = state.JOIN,    to = state.READY},
		    {name = "ev_shuffle",      from = state.JOIN,    to = state.SHUFFLE},
		    {name = "ev_deal",         from = state.SHUFFLE, to = state.DEAL},
		    {name = "ev_first_turn",    from = state.SHUFFLE,    to = state.FIRSTTURN},
		    {name = "ev_turn_after_firstturn",    from = state.FIRSTTURN,    to = state.TURN},
		    {name = "ev_turn_after_call",         from = state.CALL,    to = state.TURN},
		    {name = "ev_call",             from = state.TURN,    to = state.CALL},
		    {name = "ev_over",             from = state.CALL,    to = state.OVER},
		    {name = "ev_settle",           from = state.OVER,    to = state.SETTLE},
		    {name = "ev_restart",          from = state.SETTLE,    to = state.RESTART},
		    {name = "ev_shuffle_after_restart",          from = state.RESTART,    to = state.SHUFFLE},
		    {name = "ev_roomover",         from = state.SETTLE,    to = state.ROOMOVER},
		    {name = "ev_reset_join",       from = "*",   to = state.JOIN},               -- reset to join
		    {name = "ev_reset_ready",      from = "*",   to = state.READY},               -- reset to join
		    {name = "ev_reset_shuffle",    from = "*",   to = state.SHUFFLE},               -- reset to join
		    {name = "ev_reset_deal",       from = "*",   to = state.DEAL},               -- reset to join
		    {name = "ev_reset_turn",       from = "*",   to = state.TURN},               -- reset to join
		    {name = "ev_reset_lead",       from = "*",   to = state.LEAD},               -- reset to join
		    {name = "ev_reset_call",       from = "*",   to = state.CALL},               -- reset to join
		},
		callbacks = {
			on_join = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_ready = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_shuffle = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_deal = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_firstturn = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_turn = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		    on_call = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
			on_lead = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
			on_over = function(self, event, from, to, obj, msg) obj:on_state(event, from, to, msg) end,
		}
	})
	return alert
end

function cls:on_state(event, from, to)
	-- body
	self.alert.last_state = from
	if to == state.READY then
		self:take_ready()
	elseif to == state.SHUFFLE then
		local ok, err = xpcall(self.take_shuffle, traceback, self)
		if not ok then
			log.error(err)
		end
	elseif to == state.DEAL then
		assert(self)
		local ok, err = xpcall(self.take_deal, traceback, self)
		if not ok then
			log.error(err)
		end
	elseif to == state.FIRSTTURN then
		self:take_firstturn()
	elseif to == state.TURN then
		if from == state.FIRSTTURN then
			-- 不做任何处理
		else
			self:take_turn()
		end
	elseif to == state.CALL then
		self:take_call()
	elseif to == state.OVER then
		self:take_settle()
	end
end

function cls:is_next_state(state)
	-- body
	assert(state)
	for i=1,self.max do
		local p = assert(self.players[i])
		if not p.alert.is(state) then
			return false
		end
	end
	return true
end

function cls:on_next_state()
	-- body
	if self.alert.is(state.JOIN) then
		if self:is_next_state(Player.state.JOIN) then
			log.info('on_next_state')
			self.alert.ev_shuffle(self)
		end
	elseif self.alert.is(state.READY) then
		if self:is_next_state(Player.state.READY) then
			self.alert.ev_shuffle(self)
		end
	elseif self.alert.is(state.SHUFFLE) then
		if self:is_next_state(Player.state.DEAL) then
			self.alert.ev_first_turn(self)
		end
	elseif self.alert.is(state.CALL) then
		if self:is_next_state(Player.state.CALL) then
			self.alert.ev_turn_after_call(self)
		end
	elseif self.alert.is(state.OVER) then
		if self:is_next_state(Player.state.OVER) then
			self.alert.ev_settle(self)
		end
	elseif self.alert.is(state.SETTLE) then
		if self:is_next_state(Player.state.SETTLE) then
			if self:check_roomover() then
				self.alert.ev_roomover(self)
			end
		end
	elseif self.alert.is(state.RESTART) then
		if self:is_next_state(Player.state.RESTART) then
			self.alert.ev_shuffle(self)
		end
	elseif self.alert.is(state.ROOMOVER) then
		if self:is_next_state(Player.state.ROOMOVER) then
			skynet.send('.ROOM_MGR', 'lua', "dissolve", self.id)
		end
	end
end

function cls:next_idx()
	-- body
	self.curidx = self.curidx + 1
	if self.curidx > self.max then
		self.curidx = 1
	end
end

function cls:prev_idx()
	-- body
	if self.curidx == 1 then
		return 4
	else
		return self.curidx - 1
	end
end

function cls:incre_joined()
	-- body
	self.joined = self.joined + 1
	assert(self.joined <= self.max)
end

function cls:decre_joined()
	-- body
	self.joined = self.joined - 1
	assert(self.joined >= 0)
end

function cls:incre_online()
	-- body
	self.online = self.online + 1
	assert(self.online <= self.max)
end

function cls:decre_online()
	-- body
	self.online = self.online - 1
	assert(self.online >= 0)
end

function cls:print_cards()
	-- body
	for i,v in ipairs(self._cards) do
		print(v:describe())
	end
end

------------------------------------------
-- 服务事件
function cls:start(channel_id)
	-- body
	assert(self)
	local CMD = require "CMD"
	local channel = mc.new {
		channel = channel_id,
		dispatch = function (_, _, cmd, ...)
			-- body
			local f = assert(CMD[cmd])
			local ok, result = pcall(f, self, ... )
			if not ok then
				log.error(result)
			end
		end
	}
	self.channel = channel
	-- channel:subscribe()
	return true
end

function cls:init_data()
	-- body
	assert(self)
	-- 一局的数据无法恢复
	-- local pack = skynet.call(".DB", "lua", "read_room", self.id)
	-- if pack then
	-- 	local db_rooms = pack.db_rooms
	-- 	if #db_rooms <= 0 then
	-- 		return true
	-- 	end
	-- 	local db_room = db_rooms[1]
	-- 	local open = db_room.open
	-- 	if not open then
	-- 		return true
	-- 	end
	--     self.host = db_room.host
	--     self.open = (db_room.open == 1) and true or false
	--     self.firstidx = db_room.firstidx
	--     self.curidx = db_room.curidx
	--     self.ju = db_room.ju
	-- 	self.alert = self:create_alert(state.INITDB)
	-- 	local event = 'ev_reset_' .. db_room.state
	-- 	self.alert[event](self)
	-- 	self.alert.last_state = db_room.laststate

	-- 	-- 修改设置
	-- 	if self.open and not self.channelSubscribed then
	-- 		self.channelSubscribed = true
	-- 		self.channel:subscribe()
	-- 	end

	-- 	-- 初始化用户数据
	-- 	for _,db_user in pairs(pack.db_users) do
	-- 		local player = self.players[db_user.idx]
	-- 		player.uid = assert(db_user.uid)
	-- 		player.idx = assert(db_user.idx)
	-- 		player.chip = assert(db_user.chip)
	-- 		player:init_alert(Player.state.INITDB)
	-- 		local event = 'ev_reset_' .. db_user.state
	-- 		player.alert[event](player)
	-- 		self.uplayers[player.uid] = player
	-- 		self:incre_joined()
	-- 	end
	-- end
	return true
end

function cls:sayhi(host, users)
	-- body
	assert(self)
	self.host = host
	self.open = true
	if self.open and not self.channelSubscribed then
		self.channelSubscribed = true
		self.channel:subscribe()
	end
	for _,user in pairs(users) do
		local player = self.players[user.idx]
		player.uid = assert(user.uid)
		player.chip = assert(user.chip)
		self.uplayers[player.uid] = player
		self:incre_joined()
	end
	return true
end

function cls:save_data()
	-- body
	if not self.open then
		-- log.info("roomid = %d, save_data self._open is false", self._id)
		return
	end

	-- 打包用户数据
	local db_users = {}
	local db_room = {}
	for k,v in pairs(self.players) do
		if v.uid > 0 then      -- > 0 才是有人加入
			local db_user = {}
			db_user.uid = assert(v.uid)
			db_user.roomid = self.id
			db_user.idx = assert(v.idx)
			db_user.chip = assert(v.chip)
			db_user.state = assert(v.alert.current)
			db_users[string.format("%d", k)] = db_user
		end
	end

	-- 打包房间数据
	db_room.id = assert(self.id)
	db_room.open = assert(self.open) and 1 or 0
	db_room.host = 0

	-- gameplay data
	db_room.state      = assert(self.alert.current)
	db_room.laststate  = assert(self.alert.last_state)
	db_room.firstidx   = assert(self.firstidx)
	db_room.curidx     = assert(self.curidx)
	db_room.ju         = 0

	local data = {}
	data.db_users = db_users
	data.db_room = db_room
	skynet.call(".DB", "lua", "write_room", data)
end

function cls:close()
	-- body
	assert(self)
	-- self._open = false
	return true
end

------------------------------------------
-- 房间协议
function cls:create(uid, args)
	-- body
	assert(uid)
	assert(args)
	self.host = uid

	-- clear player
	for i=1,self.max do
		local p = self.players[i]
		assert(p:is_none())
		assert(not p.online)
	end
	self.joined = 0
	self.online = 0

	self:clear()

	self._stime = 0
	self._record = {}

	self.alert = self:create_alert(state.NONE)
	assert(self.alert.can('ev_join'))
	self.alert.ev_join(self)

	skynet.call('.CHATD', 'lua', 'room_create', self.id)
	self.open = true
	if self.open and not self.channelSubscribed then
		self.channelSubscribed = true
		self.channel:subscribe()
	end
	log.info("room create success.")
	local res = {}
	res.errorcode = 0
	res.roomid = self.id
	res.room_max = self.max
	return res
end

function cls:join(uid, agent, name, sex)
	-- body
	assert(uid and agent and name and sex)
	local res = {}
	if not self.alert.is(state.JOIN) then
		res.errorcode = 15
		return res
	end

	if self.joined >= self.max then
		res.errorcode = 16
		return res
	end

	-- 原来肯定是不存在此用户
	local p = self:get_player_by_uid(uid)
	assert(p == nil)

	local me = assert(self:find_noone())
	me.uid = uid
	me.agent = agent
	me.name = name
	me.sex = sex
	me.online = true
	self:incre_joined()
	self:incre_online()
	self.uplayers[uid] = me
	me.alert.ev_wait_join(me)

	-- 把信息存到room_mgr与chatd
	skynet.call('.ROOM_MGR', "lua", "room_join", self.id, uid, agent, me.idx, me.chip)
	skynet.call('.CHATD', "lua", "room_join", self.id, uid, agent)

	-- 返回给当前用户的信息
	local p = {
		idx   =  me.idx,
		chip  =  me.chip,
		sex   =  me.sex,
		name  =  me.name,
		state =  me.alert.current,
		online = me.online,
		cards = {},
		opcode = opcode.NONE,
		lead = {}
	}

	local res = {}
	res.errorcode = 0
	res.roomid = self.id
	res.room_max = self.max
	res.state = self.alert.current
	res.me = p
	res.ps = {}
	for _,v in ipairs(self.players) do
		if not v:is_none() and v.uid ~= uid then
			local p = {
				idx   =  v.idx,
				chip  =  v.chip,
				sex   =  v.sex,
				name  =  v.name,
				state =  v.alert.current,
				online = v.online,
				cards = {},
				opcode = opcode.NONE,
				lead  = {}
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me.idx, "big2join", args)

	-- if self.joined >= self.max and self.online >= self.max then
	-- 	self.alert.ev_ready(self)
	-- end
	return servicecode.NORET
end

function cls:rejoin(uid, agent)
	-- body
	assert(uid and agent)
	local res = { errorcode = 0 }
	log.info("rejoin uid(%d)", uid)
	local me = self:get_player_by_uid(uid)
	if me == nil then
		res.errorcode = 17
		return res
	end

	assert(not me.online)
	me.agent = agent
	me.online = true
	self:incre_online()

	if me.alert.is(Player.state.NONE) then
		me.alert.ev_wait_join(me)
	end
	-- 把信息存到
	skynet.call('.ROOM_MGR', "lua", "room_rejoin", self.id, uid, agent)
	skynet.call('.CHATD', "lua", "room_rejoin", self.id, uid, agent)

	-- sync
	local p = {
		idx   =  me.idx,
		chip  =  me.chip,
		sex   =  me.sex,
		name  =  me.name,
		state =  me.alert.current,
		online = me.online,
		cards  = me:pack_cards(),
		opcode = me.opcode,
		lead   = me:pack_leadcards()
	}

	res.errorcode = 0
	res.roomid = self.id
	res.room_max = self.max
	res.state = self.alert.current
	res.me = p
	res.ps = {}
	for _,v in ipairs(self.players) do
		if not v:is_none() and v.uid ~= uid then
			local p = {
				idx   =  v.idx,
				chip  =  v.chip,
				sex   =  v.sex,
				name  =  v.name,
				state =  v.alert.current,
				online = v.online,
				cards  = v:pack_cards(),
				opcode = v.opcode,
				lead   = v:pack_leadcards()
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me.idx, "big2rejoin", args)

	-- if self.joined >= self.max and self.online >= self.max then
	-- 	if self.alert.is(state.JOIN) then
	-- 		-- self.alert.ev_shuffle(self)
	-- 		self.alert.ev_ready(self)
	-- 	end
	-- end
	return servicecode.NORET
end

function cls:leave(uid)
	-- body
	local p = self:get_player_by_uid(uid)
	assert(p)
	p.online = false
	p.uid = 0
	self:decre_online()
	self:decre_joined()
	-- self.alert.ev_reset_join()

	-- 把信息存到
	skynet.call('.ROOM_MGR', "lua", "room_leave", self.id, uid)
	skynet.call('.CHATD', "lua", "room_leave", self.id, uid)

	local res = {}
	res.errorcode = 0
	skynet.retpack(res)

	local args = {}
	args.idx = p.idx
	self:push_client_except_idx(p.idx, "big2leave", args)
	return servicecode.NORET
end

function cls:afk(uid)
	-- body
	log.info('roomid = %d, uid(%d) afk', self.id, uid)
	local p = self:get_player_by_uid(uid)
	assert(p.online)
	p.online = false
	self:decre_online()
	-- self.alert.ev_reset_join(self)
	-- 把信息存到
	skynet.call('.ROOM_MGR', "lua", "room_afk", self.id, uid)
	skynet.call('.CHATD', "lua", "room_afk", self.id, uid)

	local args = {}
	args.idx = p.idx
	self:push_client_except_idx(p.idx, "offline", args)
	return true
end

function cls:recycle()
	-- body
	assert(self)
	skynet.call('.CHATD', 'lua', 'room_recycle', self.id)
	self.open = false
	return true
end

------------------------------------------
-- 大佬2协议
function cls:step(idx, mock)
	-- body
	assert(idx)
	local res = {}
	if not self.open then
		res.errorcode = 1
		return res
	end
	if idx < 1 or idx > self.max then
		res.errorcode = 1
		return res
	end
	-- 检测此玩家是否
	local p = self.players[idx]
	if p:is_none() then
		res.errorcode = 1
		return res
	end
	if self.alert.is(state.JOIN) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_join(p)
	elseif self.alert.is(state.READY) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_ready(p)
	elseif self.alert.is(state.SHUFFLE) then
		log.info('step : shuffle')
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		-- 此玩家发牌完成
		p.alert.ev_deal(p)
	elseif self.alert.is(state.DEAL) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		-- 此玩家发牌完成
		p.alert.ev_deal(p)
	elseif self.alert.is(state.CALL) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_call(p)
	elseif self.alert.is(state.OVER) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_over(p)
	elseif self.alert.is(state.SETTLE) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_settle(p)
	elseif self.alert.is(state.ROOMOVER) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		p.alert.ev_roomover(p)
	end
	return servicecode.NORET
end

function cls:ready(idx)
	-- body
	local res = {}
	if not self.open then
		res.errorcode = 1
		return res
	end
	if not self.alert.is(state.READY) then
		res.errorcode = 5
		res.idx = idx
		return res
	end
	local p = self.players[idx]
	if p == nil then
		res.errorcode = 1
		return res
	end
	if not p.alert.is(Player.state.WAIT_READY) then
		res.errorcode = 19
		res.idx = idx
		return res
	end
	-- 推送准备状态

	-- 转移状态
	res.errorcode = 0
	res.idx = idx
	skynet.retpack(res)

	p.alert.ev_ready()
	return servicecode.NORET
end

function cls:lead(idx, code, xleadcards, mock)
	-- body
	if mock then
		assert(idx == self.curidx)
		local p = assert(self.players[idx])
		assert(p:lead(ltype, cards) == 0)
		self.alert.ev_lead(self)
	else
		local res = {}
		if not self.open then
			res.errorcode = 20
			return res
		end
		if idx ~= self.curidx then
			res.errorcode = 21
			return res
		end
		-- 检测此玩家是否
		local p = self.players[idx]
		if p:is_none() then
			res.errorcode = 17
			return res
		end
		-- 真正出牌的地方
		local xcards = {}
		for i,v in ipairs(xleadcards.cards) do
			local card = assert(self._kcards[v.value])
			table.insert(xcards, card)
		end
		-- 检测出牌类型对不对
		local lt = to_lead_type.parseLeadtype(xcards)
		if lt ~= xleadcards.leadtype then
			res.errorcode = 22
			return res
		end
		local aLeadcards = leadcards.new(xleadcards.leadtype, xcards)
		if self.previdx ~= 0 then
			local prevp = self.players[self.previdx]
			if not aLeadcards:mt(prevp.leadcards) then
				res.errorcode = 1
				return res
			end
		end
		local errorcode = p:lead(code, aLeadcards)
		if errorcode == 0 then
			self.previdx = self.curidx
			res.errorcode = errorcode
			skynet.retpack(res)
			self.alert.ev_call(self)
			return servicecode.NORET
		else
			res.errorcode = errorcode
			return res
		end
	end
end

function cls:call(idx, code, args, mock)
	-- body
	if mock then
	else
		local res = {}
		if not self.open then
			res.errorcode = 20
			return res
		end
		if idx ~= self.curidx then
			res.errorcode = 21
			return res
		end
		local p = self.players[idx]
		if p.opcode == opcode.PASS then
			res.errorcode = 17
			return res
		end
		if code == opcode.PASS then
			p:call(idx, code)
			res.errorcode = 0
			skynet.retpack(res)
		elseif code == opcode.LEAD then
			return self:lead(idx, code, args.lead)
		else
			res.errorcode = 1
			return res
		end
		-- 转移状态
		self.alert.ev_call()
		return servicecode.NORET
	end
end

-- 此协议现在没有用
function cls:restart(idx)
	-- body
	assert(self)
	assert(idx)
end

------------------------------------------
-- turn state
function cls:take_ready()
	-- body
	self:emit_player_event("ev_wait_ready")
	-- self:push_client("big2take_ready")
end

function cls:take_shuffle()
	-- body
	assert(self.alert.is(state.SHUFFLE))

	-- 开始洗牌后才开始计算消耗品
	local ok = skynet.call('.ROOM_MGR', 'lua', 'room_is_1stju', self.id)
	if ok then
		-- 消耗房主的门票
		-- send agent
		-- local p = self:get_player_by_uid(self.host)
		-- local addr = p:get_agent()
		-- local ok = skynet.call(addr, "lua", "alter_rcard", -1)
		-- assert(ok)
	end

	-- 记录所有消息
	self._stime = skynet.now()
	self._record = {}

	-- for i=1,self._cardssz do
	-- 	self._cards[i]:clear()
	-- end

	-- 洗牌算法
	-- assert(#self._cards == self._cardssz)
	-- for i=self._cardssz-1,1,-1 do
	-- 	local swp = math.floor(math.random(1, 1000)) % self._cardssz + 1
	-- 	while swp == i do
	-- 		swp = math.floor(math.random(1, 1000)) % self._cardssz + 1
	-- 	end
	-- 	local tmp = assert(self._cards[i])
	-- 	self._cards[i] = assert(self._cards[swp], swp)
	-- 	self._cards[swp] = tmp
	-- end
	-- assert(#self._cards == self._cardssz)
	-- self:print_cards()

	-- self:record("shuffle", args)
	-- self.alert.ev_deal(self)

	self:take_deal()
end

function cls:take_deal()
	-- body

	-- 发牌
	-- self:print_cards()
	local event = 'ev_' .. Player.state.WAIT_DEAL
	self:emit_player_event(event)
	for i=1,52,4 do
		local k = i
		for j=1,4 do
			local card =  assert(self._cards[k])
			local p = self.players[j]
			p:insert(card)
			k = k + 1
		end
	end

	self.players[1]:print_cards()

	local p1 = self.players[1]:pack_cards()
	local p2 = self.players[2]:pack_cards()
	local p3 = self.players[3]:pack_cards()
	local p4 = self.players[4]:pack_cards()

	local args = {}
	args.firstidx  = self.firstidx
	args.firsttake = self.firstidx
	args.deal = {}
	table.insert(args.deal, { idx = 1, cards = p1 })
	table.insert(args.deal, { idx = 2, cards = p2 })
	table.insert(args.deal, { idx = 3, cards = p3 })
	table.insert(args.deal, { idx = 4, cards = p4 })

	self:record("big2deal", args)
	self:push_client("big2deal", args)

	-- 超时断连后
	if MOCK then
		skynet.timeout(100 * 20, function ()
			-- body
			for i=1,4 do
				self:step(i, true)
			end
		end)
	end
end

function cls:take_firstturn()
	-- body
	assert(self.alert.is(state.FIRSTTURN))
	-- 把房间状态转移到turn
	self.alert.ev_turn_after_firstturn(self)

	-- 玩家状态转移
	self.curidx = 1
	local p = self.players[self.curidx]
	assert(p.alert.can('ev_wait_turn_after_deal'))
	p.alert.ev_wait_turn_after_deal(p)

	for i=1,self.max do
		if i ~= self.curidx then
			local p = self.players[i]
			p.alert.ev_watch_after_deal(p)
		end
	end

	local args = {}
	args.idx = self.curidx
	args.countdown = self.countdown
	-- self:record("take_turn", args)
	self:push_client("big2take_turn", args)

	if MOCK then
		skynet.timeout(100 * 20, function ()
			-- body
			local p = self.players[self.curidx]
			local card = p.cards[1]
			self:lead(self.curidx, leadtype.SINGLE, {{pos=card.pos, value=card.value}}, true)
		end)
	end
end

-- 当前用户需要出牌，可能摸了一个牌，也可能是其他
function cls:take_turn()
	-- body
	assert(self.alert.is(state.TURN))
	assert(self.curidx)
	-- 选择下一个
	local who = 0
	for i=1,3 do
		local idx = self.curidx + i
		if idx > self.max then
			idx = 1
		end
		local p = self.players[idx]
		if p.opcode ~= opcode.PASS then
			who = idx
			break
		end
	end
	if who == 0 then
		-- 清理这一轮玩家状态
		for i=1,self.max do
			local p = self.players[i]
			p.opcode = opcode.NONE
		end
		self.previdx = 0
	else
		self.curidx = who
	end

	local p = self.players[self.curidx]
	assert(p.alert.can('ev_wait_turn_after_call'))
	p.alert.ev_wait_turn_after_call(p)

	for i=1,self.max do
		if i ~= self.curidx then
			local p = self.players[i]
			p.alert.ev_watch_after_call(p)
		end
	end

	local args = {}
	args.idx = self.curidx
	args.countdown = self.countdown
	-- self:record("take_turn", args)
	self:push_client("big2take_turn", args)

	if MOCK then
		skynet.timeout(100 * 20, function ()
			-- body
			local p = self.players[self.curidx]
			local card = p.cards[1]
			self:lead(self.curidx, leadtype.SINGLE, {{pos=card.pos, value=card.value}}, true)
		end)
	end
end

function cls:take_call()
	-- body
	assert(self.alert.is(state.CALL))
	local p = assert(self.players[self.curidx])
	p.alert.ev_wait_call_after_wait_turn(p)

	for i=1,self.max do
		if i ~= self.curidx then
			local p = assert(self.players[i])
			p.alert.ev_wait_call_after_watch(p)
		end
	end

	local args = {}
	args.idx = self.curidx
	args.opcode = p.opcode
	args.lead = p:pack_leadcards()
	self:push_client("big2call", args)

	if MOCK then
		skynet.timeout(100 * 20, function ()
			-- body
			for i=1,self.max do
				self:step(i, true)
			end
		end)
	end
end

function cls:take_over()
	-- body
	assert(self.alert.is(state.OVER))
	self:emit_player_event('ev_wait_over')

	self:record("big2over")
	self:push_client("big2over")
end

-- 结算会检查是重新开始一局，还是房间结束
function cls:take_settle()
	-- body
	assert(self.alert.is(state.SETTLE))

	local args = {}
	args.settles = self.settles

	self:record("settle", args)
	self:push_client("settle", args)
end

function cls:take_restart()
	-- body
	assert(self.alert.is(state.RESTART))

	-- 可能有什么需要清理
	self:clear()

	for i=1,self._max do
		self._players[i]:take_restart()
	end

	self:push_client("take_restart")
end

function cls:take_roomover()
	-- body
	assert(self.alert.is(state.ROOMOVER))
	for i=1,self.max do
		local p = self.players[i]
		if p.online then
			skynet.call(p.agent, 'lua', 'roomover')
		else
			skynet.call('.OFFAGENT', 'lua', 'write_offuser_room', p.uid)
		end
	end
	skynet.send('.ROOM_MGR', 'lua', 'dissolve', self.id)
end

return cls
