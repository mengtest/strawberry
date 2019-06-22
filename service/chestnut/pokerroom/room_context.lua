local skynet = require "skynet"
local mc = require "skynet.multicast"
local ds = require "skynet.datasheet"
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
state.SHUFFLE    = "shuffle"   -- 此状态下洗牌,[[ perflopsblind, perflopbbblind ]]
state.DEAL       = "deal"      -- 此状态发牌   [[ perflop, flop, turn, river ]]
state.FIRSTTURN  = "firstturn" -- 第一个人出牌
state.TURN       = "turn"      -- 轮谁出牌     [[ perflop, flop, turn, river ]]
state.CALL       = "call"      -- 只有pass命令 [[ perflop, flop, turn, river ]]
state.OVER       = "over"      -- 结束
state.SETTLE     = "settle"    -- 结算
state.RESTART    = "restart"   -- 重新开始
state.ROOMOVER   = 'roomover'

local gameplay = {}
gameplay.NONE             = "none"
gameplay.PERFLOPSBLIND    = "perflopsblind"
gameplay.PERFLOPBBLIND    = "perflopbblind"
gameplay.PERFLOP          = "perflop"         -- 每个玩家发两张牌，大盲注后的第一个人开始
gameplay.FLOP             = "flop"            -- 公共牌发三张
gameplay.TURN             = "turn"            -- 公共牌发一张
gameplay.RIVER            = "river"

local MOCK = false

local cls = class("RoomContext")

function cls:ctor()
	-- body
	-- pre players
	self.players = {}
	for i=1,9 do
		local tmp = Player.new(self, 0, 0)
		tmp.idx = i
		self.players[i] = tmp
	end

	-- 房间数据
	self.channel = nil
	self.channelSubscribed = false
	self.id = 0
	self.open = false
	self.type = 0         -- 房间是私有房间还是匹配房间，私有房间是host值
	self.mode = 0         -- 房间模式
	self.rule = {}        -- 房间规则，作为模式的补充
	self.host = 0

	-- 房间玩家
	self.joined = 0
	self.online = 0
	self.uplayers = {}    -- 已经坐在桌子上的人
	self.watchers = {}    -- 加入的观察者
	
	-- 卡牌
	self._cards = {}         -- 洗牌
	self._cardssz = 52
	self._dealcardidx = 1
	self._kcards = {}
	self:init_cards()

	-- gameplay
	self.firstidx = 0           -- 拿牌头家
	self.sblindidx = 0          -- 小盲注索引
	self.bblindidx = 0          -- 大盲注索引
	self.previdx = 0            -- 上一个玩家出牌
	self.curidx = 0             -- 玩家索引，当前轮到谁
	self.alert = self:create_alert(state.START)
	self.alert.last_state = state.NONE
	self.playalert = self:create_gameplay_alert(gameplay.NONE)
	self.flopCards = {}
	self.turnCard = nil
	self.riverCard = nil
	self.callround = 0
	self.settles = {}           -- 在结束的时候已经完成
	self.maxju = 0              -- 玩的局数

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
	self.firstidx = 0           -- 拿牌头家
	self.sblindidx = 0          -- 小盲注索引
	self.bblindidx = 0          -- 大盲注索引
	self.previdx = 0            -- 上一个玩家出牌
	self.curidx = 0             -- 玩家索引，当前轮到谁
	self.alert = self:create_alert(state.START)
	self.alert.last_state = state.NONE
	self.playalert = self:create_gameplay_alert(gameplay.NONE)
	self.flopCards = {}
	self.turnCard = nil
	self.riverCard = nil
	self.callround = 0
	self.settles = {}           -- 在结束的时候已经完成
	self.maxju = 0              -- 玩的局数
end

function cls:find_noone()
	-- body
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	if self.joined >= xmode.join then
		return nil
	end
	for i=1,xmode.join do
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

-- cards
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

function cls:print_cards()
	-- body
	for i,v in ipairs(self._cards) do
		print(v:describe())
	end
end

function cls:next_card()
	-- body
	local card = assert(self._cards[self._dealcardidx])
	self._dealcardidx = self._dealcardidx + 1
	return card
end

-- push
function cls:push_client(name, args)
	-- body
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
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
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
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

------------------------------------------
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
		    {name = "ev_join_after_restart",          from = state.RESTART,    to = state.JOIN},
			{name = "ev_roomover",         from = state.SETTLE,    to = state.ROOMOVER},
			-------------------------------------------------------------------------------	下面的没有用		
		    {name = "ev_reset_join",       from = "*",   to = state.JOIN},               -- reset to join
		    {name = "ev_reset_ready",      from = "*",   to = state.READY},              -- reset to join
		    {name = "ev_reset_shuffle",    from = "*",   to = state.SHUFFLE},            -- reset to join
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
	if to == state.JOIN then
	elseif to == state.READY then
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
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = assert(self.players[i])
		if not p:is_none() and
			p.dealed and
			not p.alert.is(state) then
			return false
		end
	end
	return true
end

function cls:on_next_state()
	-- body
	if self.alert.is(state.JOIN) then
	elseif self.alert.is(state.READY) then
		if self:is_next_state(Player.state.READY) then
			self.alert.ev_shuffle(self)
		end
	elseif self.alert.is(state.SHUFFLE) then
		if self:is_next_state(Player.state.DEAL) then
			self.alert.ev_first_turn(self)
		end
	elseif self.alert.is(state.DEAL) then
		if self:is_next_state(Player.state.DEAL) then
			self.alert.ev_first_turn()
		end
	elseif self.alert.is(state.CALL) then
		if self:is_next_state(Player.state.CALL) then
			if self.playalert.is(gameplay.PERFLOPSBLIND) then
				self.playalert.ev_perflopbblind(self)
			elseif self.playalert.is(gameplay.PERFLOPBBLIND) then
				self.playalert.ev_perflop(self)
			else
				self.alert.ev_turn_after_call(self)
			end
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

function cls:on_doshuffle()
	-- body
	-- 判断join玩家人数
	if self.alert.current < state.SHUFFLE then
		local cnt = 0
		local roommode = ds.query('roommode')
		local xmode = roommode[tostring(self.mode)]
		for i=1,xmode.join do
			local p = self.players[i]
			if p.alert.is(Player.state.JOIN) then
				cnt = cnt + 1
			end
		end
		if cnt >= 2 then
			self.alert.ev_shuffle(self)
		end
	end
end

-- 创建gameplay状态机
function cls:create_gameplay_alert(initial_state)
	-- body
	assert(self)
	local alert = fsm.create({
		initial = initial_state,
		events = {
			{name = "ev_perflopsblind",        from = gameplay.NONE,             to = gameplay.PERFLOPSBLIND},
		    {name = "ev_perflopbblind",        from = gameplay.PERFLOPSBLIND,    to = gameplay.PERFLOPBBLIND},
		    {name = "ev_perflop",              from = gameplay.PERFLOPBBLIND,    to = gameplay.PERFLOP},
		    {name = "ev_flop",                 from = gameplay.PERFLOP,          to = gameplay.FLOP},
		    {name = "ev_turn",                 from = gameplay.FLOP,             to = gameplay.TURN},
			{name = "ev_river",                from = gameplay.TURN,             to = gameplay.RIVER},
			{name = "ev_none_after_river",     from = gameplay.RIVER,            to = gameplay.NONE}
		},
		callbacks = {
			on_perflopsblind = function(self, event, from, to, obj, msg) obj:on_gameplay_state(event, from, to, msg) end,
		    on_perflopbblind = function(self, event, from, to, obj, msg) obj:on_gameplay_state(event, from, to, msg) end,
		    on_perflop = function(self, event, from, to, obj, msg) obj:on_gameplay_state(event, from, to, msg) end,
		}
	})
	return alert
end

function cls:on_gameplay_state(event, from, to)
	-- body
	if to == gameplay.PERFLOPSBLIND then
		self:take_play_perflopsblind()
	elseif to == gameplay.PERFLOPBBLIND then
		self:take_play_perflopbblind()
	elseif to == gameplay.PERFLOP then
		self:take_play_perflop()
	elseif to == gameplay.FLOP then
		self:take_play_flop()
	elseif to == gameplay.TURN then
		self:take_play_turn()
	elseif to == gameplay.RIVER then
		self:take_play_river()
	end
end

-- 对玩家的操作
function cls:next_idx()
	-- body
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	self.curidx = self.curidx + 1
	if self.curidx > xmode.join then
		self.curidx = 1
	end
	local p = assert(self.players[self.curidx])
	while not p.dealed and 
		(p.opcode == opcode.FOLD or
		p.opcode == opcode.ALLIN) do
		self.curidx = self.curidx + 1
		if self.curidx > xmode.join then
			self.curidx = 1
		end
		p = assert(self.players[self.curidx])
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
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	self.joined = self.joined + 1
	assert(self.joined <= xmode.join)
end

function cls:decre_joined()
	-- body
	self.joined = self.joined - 1
	assert(self.joined >= 0)
end

function cls:incre_online()
	-- body
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	self.online = self.online + 1
	assert(self.online <= xmode.join)
end

function cls:decre_online()
	-- body
	self.online = self.online - 1
	assert(self.online >= 0)
end

-- 所有玩家都转移状态
function cls:emit_player_event(event)
	-- body
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = assert(self.players[i])
		if not p:is_none() and
			p.dealed then
			p.alert[event](p)
		end
	end
end

function cls:count_player_sitdown()
	local cnt = 0
	for _,v in pairs(self.uplayers) do
		if v.online and v.sitdown then
			cnt = cnt + 1
		end
	end
	return cnt
end

function cls:clear_player_dealed()
	-- body
	assert(self)
end

-- 计算剩余数
function cls:count_left()
	-- body
	local cnt = 0
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = self.players[i]
		if p.dealed then
			if p.opcode ~= opcode.FOLD then
				cnt = cnt + 1
			end
		end
	end
	return cnt
end

------------------------------------------
-- 服务事件
function cls:start(channel_id)
	-- body
	assert(self)
	local CMD = require "cmd"
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

function cls:sayhi(type, mode, host, users)
	-- body
	assert(self)
	self.open = true
	self.type = type
	self.mode = mode
	self.host = host
	if self.open and not self.channelSubscribed then
		self.channelSubscribed = true
		self.channel:subscribe()
	end
	if type == 1 then
		for _,user in pairs(users) do
			local player = self.players[user.idx]
			player.uid = assert(user.uid)
			player.chip = assert(user.chip)
			self.uplayers[player.uid] = player
			self:incre_joined()
		end
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
function cls:create(uid)
	-- body
	assert(uid)
	self.host = uid

	-- clear player
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = self.players[i]
		assert(p:is_none())
		assert(not p.online)
	end
	self.joined = 0
	self.online = 0
	self.uplayers = {}
	self.watchers = {}

	-- clear gameplay
	self:clear()

	-- clear record
	self._stime = 0
	self._record = {}
	
	skynet.call('.CHATD', 'lua', 'room_create', self.id, skynet.self())
	print(self.alert.can('ev_join'))
	self.alert.ev_join(self)

	log.info("room create success.")
	local res = {}
	res.errorcode = 0
	res.roomid = self.id
	res.room_max = xmode.join
	return res
end

function cls:join(uid, agent, name, sex)
	-- body
	assert(uid and agent and name and sex)
	local res = {}

	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	if self.joined >= xmode.join then
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
	me.alert.ev_wait_join(me)
	me.sitdown = false
	self:incre_joined()
	self:incre_online()
	if self.alert.is(state.JOIN) then
		self.uplayers[me.uid] = me
		me.sitdown = true
	else
		table.insert(self.watchers, me)
	end
	
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
		sitdown = me.sitdown
	}

	local res = {}
	res.errorcode = 0
	res.roomid = self.id
	res.mode   = self.mode
	res.state  = self.alert.current
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
				sitdown = v.sitdown,
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me.idx, "pokerjoin", args)

	-- 判断人数是否进入下一个状态
	if self.online >= 2 then
		if self.alert.is(state.JOIN) then
			self.alert.ev_ready(self)
		end
	end
	return servicecode.NORET
end

function cls:rejoin(uid, agent)
	-- body
	assert(uid and agent)
	local res = { errorcode = 0 }
	local me = self:get_player_by_uid(uid)
	if me == nil then
		res.errorcode = 17
		return res
	end

	assert(not me.online)
	me.agent = agent
	me.online = true
	me.sitdown = true
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
		sitdown = me.sitdown,
	}

	res.errorcode = 0
	res.roomid = self.id
	res.mode   = self.mode
	res.state  = self.alert.current
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
				sitdown = v.sitdown,
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me.idx, "pokerrejoin", args)

	-- if self.joined >= self.max and self.online >= self.max then
	-- 	if self.alert.is(state.JOIN) then
	-- 		-- self.alert.ev_shuffle(self)
	-- 		self.alert.ev_ready(self)
	-- 	end
	-- end
	return servicecode.NORET
end

function cls:afk(uid)
	-- body
	log.info('roomid = %d, uid(%d) afk', self.id, uid)
	local p = self:get_player_by_uid(uid)
	assert(p.online)
	p.online = false
	self:decre_online()
	-- 把信息存到
	skynet.call('.ROOM_MGR', "lua", "room_afk", self.id, uid)
	skynet.call('.CHATD', "lua", "room_afk", self.id, uid)

	log.info('room(%d) join %d', self.id, self.joined)
	-- if self.joined == 1 then
	-- 	skynet.call(p.agent, 'lua', 'room_leave')
	-- elseif self.playalert.is(gameplay.NONE) then
	-- 	skynet.call(p.agent, 'lua', 'room_leave')
	-- else
	-- 	local args = {}
	-- 	args.idx = p.idx
	-- 	self:push_client_except_idx(p.idx, "offline", args)
	-- end
	return true
end

function cls:leave(uid)
	-- body
	log.info('uid(%d) leave', uid)
	local p = self:get_player_by_uid(uid)
	assert(p)
	if p.online then
		p.online = false
		self:decre_online()
	end
	p.uid = 0
	p.sitdown = false
	p.alert.ev_reset_none()
	self:decre_joined()
	self.uplayers[uid] = nil

	-- 把信息存到
	skynet.call('.ROOM_MGR', "lua", "room_leave", self.id, uid)
	skynet.call('.CHATD', "lua", "room_leave", self.id, uid)

	local res = {}
	res.errorcode = 0
	skynet.retpack(res)

	local args = {}
	args.idx = p.idx
	self:push_client_except_idx(p.idx, "pokerleave", args)
	return servicecode.NORET
end

function cls:recycle()
	-- body
	assert(self)
	skynet.call('.CHATD', 'lua', 'room_recycle', self.id)
	self.open = false
	return true
end

------------------------------------------
-- 德州协议
function cls:step(idx, mock)
	-- body
	assert(idx)
	local res = {}
	if not self.open then
		res.errorcode = 1
		return res
	end
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	if idx < 1 or idx > xmode.join then
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
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		if self.playalert.is(gameplay.PERFLOPSBLIND) then
			self.playalert.ev_perflopbblind(self)
		elseif self.playalert.is(gameplay.PERFLOPBBLIND) then
			self.playalert.on_perflop(self)
		end
	elseif self.alert.is(state.DEAL) then
		if not mock then
			res.errorcode = 0
			skynet.retpack(res)
		end
		-- 此玩家发牌完成
		p.alert.ev_first_turn(p)
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

function cls:call(idx, code, args, mock)
	-- body
	if mock then
	else
		assert(self.alert.is(state.TURN))
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
		p:call(idx, code)
		res.errorcode = 0
		skynet.retpack(res)
 
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

function cls:joinedx(idx)
	-- body
	local res = {}
	if not self.open then
		res.errorcode = 1
		return res
	end
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	if idx < 1 or idx > xmode.join then
		res.errorcode = 1
		return res
	end
	-- 检测此玩家是否
	local p = self.players[idx]
	if p:is_none() then
		res.errorcode = 1
		return res
	end
	p.alert.ev_join(p)
	res.errorcode = 0
	return res
end

------------------------------------------
-- turn state
function cls:take_ready()
	-- 判断watchers里面的
	assert(self.alert.is(state.SHUFFLE))
	for _,v in ipairs(self.watchers) do
		self.uplayers[v.uid] = v
		v.sitdown = true
	end

	if #self.watchers > 0 then
		-- 推送
	end
	if self.online >= 2 then
		self.alert.ev_shuffle(self)
	end
end

function cls:take_shuffle()
	-- body
	-- 此时洗牌，不发牌
	assert(self.alert.is(state.SHUFFLE))

	-- 开始洗牌后才开始计算消耗品
	-- local ok = skynet.call('.ROOM_MGR', 'lua', 'room_is_1stju', self.id)
	-- if ok then
		-- 消耗房主的门票
		-- send agent
		-- local p = self:get_player_by_uid(self.host)
		-- local addr = p:get_agent()
		-- local ok = skynet.call(addr, "lua", "alter_rcard", -1)
		-- assert(ok)
	-- end

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

	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = assert(self.players[i])
		if not p:is_none() and
			p.online and
			p.sitdown then
			p.dealed = true
		end
	end
	self.playalert.ev_perflopsblind(self)
end

function cls:take_deal()
	-- body
	assert(self.assert.is(state.DEAL))
	local args = {}
	args.sblindidx  = assert(self.sblindidx)
	args.bblindidx  = assert(self.bblindidx)

	-- 最开阶段发牌，每个人发两张牌
	if self.playalert.is(gameplay.PERFLOP) then
		args.state = 'perflop'
		local roommode = ds.query('roommode')
		local xmode = roommode[tostring(self.mode)]
		self:emit_player_event('ev_wait_deal_after_join')
		for _=1,2 do
			for j=1,xmode.join do
				local p = assert(self.players[j])
				if p.dealed then
					local card =  self:next_card()
					p:insert(card)
				end
			end
		end
	elseif self.playalert.is(gameplay.FLOP) then
		-- 公共发三张牌
		args.state = 'flop'
		local cards = {}
		for _=1,3 do
			local card = self:next_card()
			table.insert(cards, card)
		end
		self.flopCards = cards
	elseif self.playalert.is(gameplay.TURN) then
		args.state = 'turn'
		self.turnCard = self:next_card()
	elseif self.playalert.is(gameplay.RIVER) then
		args.state = 'river'
		self.riverCard = self:next_card()
	end

	if self.playalert.current >= gameplay.PERFLOP then
		local perflop = {}
		local roommode = ds.query('roommode')
		local xmode = roommode[tostring(self.mode)]
		for i=1,xmode.join do
			local xperflop = {}
			local p = assert(self.players[i])
			if p.dealed then
				xperflop.idx = p.idx
				xperflop.cards = p:pack_cards()
			end
			table.insert(perflop, xperflop)
		end
	end
	if self.playalert.current >= gameplay.FLOP then
		local cc = {}
		for k,v in pairs(self.flopCards) do
			local c = {value=v.value, pos=v.pos}
			table.insert(cc, c)
		end
		args.flop = cc
	end
	if self.playalert.current >= gameplay.TURN then
		local c = {value=self.turnCard.value, pos=self.turnCard.pos}
		args.turn = c
	end
	if self.playalert.current >= gameplay.RIVER then
		local c = {value=self.riverCard.value, pos=self.riverCard.pos}
		args.river = c
	end

	self:record("pokerdeal", args)
	self:push_client("pokerdeal", args)

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
	local roommode = ds.query('roommode')

	-- 判断谁先叫
	if self.playalert.is(gameplay.PERFLOP) then
		self.curidx = self.bblindidx
		self:next_idx()
		self.previdx = self.curidx          -- 用这两个相等判断是否是起始点
		self.firstidx = self.curidx
		local p = self.players[self.curidx]
		while not p.dealed do
			self:next_idx()
			p = self.players[self.curidx]
		end
	elseif self.playalert.is(gameplay.FLOP) then
		self.curidx = self.sblindidx
		local p = self.players[self.curidx]
	elseif self.playalert.is(gameplay.TURN) then
	elseif self.playalert.is(gameplay.RIVER) then
	end

	-- 下面都一样
	local p = self.players[self.curidx]
	assert(p.alert.can('ev_wait_turn_after_deal'))
	p.alert.ev_wait_turn_after_deal(p)

	for i=1,xmode.join do
		if i ~= self.curidx then
			local p = self.players[i]
			if p.dealed then
				p.alert.ev_watch_after_deal(p)
			end
		end
	end

	local args = {}
	args.idx = self.curidx
	args.countdown = self.countdown
	-- self:record("take_turn", args)
	self:push_client("pokertake_turn", args)

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
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	if self.playalert.is(gameplay.PERFLOP) then
		-- 1.判断结束没有
		-- 2.判断谁下一个
		-- 3.一轮后，加注是否还要加

		self.curidx = self.bblindidx
		self:next_idx()
		self.previdx = self.curidx          -- 用这两个相等判断是否是起始点
		local p = self.players[self.curidx]
		while not p.dealed do
			self:next_idx()
			p = self.players[self.curidx]
		end
	elseif self.playalert.is(gameplay.FLOP) then
		self.curidx = self.sblindidx
		local p = self.players[self.curidx]
	elseif self.playalert.is(gameplay.TURN) then
	elseif self.playalert.is(gameplay.RIVER) then
	end

	-- 下面都一样
	local p = self.players[self.curidx]
	assert(p.alert.can('ev_wait_turn_after_call'))
	p.alert.ev_wait_turn_after_call(p)

	for i=1,xmode.join do
		if i ~= self.curidx then
			local p = self.players[i]
			p.alert.ev_watch_after_call(p)
		end
	end

	local args = {}
	args.idx = self.curidx
	args.countdown = self.countdown
	-- self:record("take_turn", args)
	self:push_client("pokertake_turn", args)

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
	-- 主要是广播
	assert(self.alert.is(state.CALL))
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]

	local p = assert(self.players[self.curidx])
	p.alert.ev_wait_call_after_wait_turn(p)

	for i=1,xmode.join do
		if i ~= self.curidx then
			local p = assert(self.players[i])
			p.alert.ev_wait_call_after_watch(p)
		end
	end

	local args = {}
	args.idx = self.curidx
	args.opcode = p.opcode
	args.lead = p:pack_leadcards()
	self:push_client("pokercall", args)

	if MOCK then
		skynet.timeout(100 * 20, function ()
			-- body
			for i=1,xmode.join do
				self:step(i, true)
			end
		end)
	end
end

function cls:take_over()
	-- body
	assert(self.alert.is(state.OVER))
	self:emit_player_event('ev_wait_over')

	self:record("pokerover")
	self:push_client("pokerover")
end

-- 结算会检查是重新开始一局，还是房间结束
function cls:take_settle()
	-- body
	assert(self.alert.is(state.SETTLE))

	local args = {}
	args.settles = self.settles

	self:record("pokersettle", args)
	self:push_client("pokersettle", args)
end

function cls:take_restart()
	-- body
	assert(self.alert.is(state.RESTART))

	-- 可能有什么需要清理
	self:clear()

	for i=1,self._max do
		self._players[i]:take_restart()
	end

	self:push_client("pokertake_restart")
end

function cls:take_roomover()
	-- body
	assert(self.alert.is(state.ROOMOVER))
	local roommode = ds.query('roommode')
	local xmode = roommode[tostring(self.mode)]
	for i=1,xmode.join do
		local p = self.players[i]
		if p.online then
			skynet.call(p.agent, 'lua', 'roomover')
		else
			skynet.call('.OFFAGENT', 'lua', 'write_offuser_room', p.uid)
		end
	end
	skynet.send('.ROOM_MGR', 'lua', 'dissolve', self.id)
end

------------------------------------------
-- turn gameplay state
function cls:take_play_perflopsblind()
	-- body
	assert(self.playalert.is(gameplay.SHUFFLE))
	assert(self.playalert.is(gameplay.PERFLOPSBLIND))
	self.firstidx = 1
	self.curidx = 1
	self:next_idx()
	self.sblindidx = self.curidx

	local args = {}
	args.idx = self.curidx
	args.opcode = opcode.SBLIND
	args.coin	= 100
	self:push_client("pokercall", args)
end

function cls:take_play_perflopbblind()
	-- body
	assert(self.playalert.is(gameplay.PERFLOPBBLIND))
	self:next_idx()
	self.bblindidx = self.curidx

	local args = {}
	args.idx = self.curidx
	args.opcode = opcode.BBLIND
	args.coin	= 100
	self:push_client("pokercall", args)
end

function cls:take_play_perflop()
	-- body
	assert(self.playalert.is(gameplay.PERFLOP))
	self.alert.ev_deal(self)
end

function cls:take_play_flop()
	-- body
	assert(self.playalert.is(gameplay.FLOP))
	self.alert.ev_deal(self)
end

function cls:take_play_turn()
	-- body
	assert(self.playalert.is(gameplay.TURN))
	self.alert.ev_deal(self)
end

function cls:take_play_river()
	-- body
	assert(self.playalert.is(gameplay.RIVER))
	self.alert.ev_deal(self)
end

return cls
