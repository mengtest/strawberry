local skynet = require "skynet"
local ds = require "skynet.datasheet"
local json = require "rapidjson"
local list = require "common.list"
local util = require "common.utils"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"
local card = require "chestnut.mahjongroom.card"
local player = require "chestnut.mahjongroom.player"
local opcode = require "chestnut.mahjongroom.opcode"
local hutype = require "chestnut.mahjongroom.hutype"
local jiaotype = require "chestnut.mahjongroom.jiaotype"
local region = require "chestnut.mahjongroom.region"
local humultiple = require "chestnut.mahjongroom.humultiple"
local exist = require "chestnut.mahjongroom.existhu"
local overtype = require "chestnut.mahjongroom.overtype"
local gangmultiple = require "chestnut.mahjongroom.gangmultiple"
local table_mgr = require "mjlib.base_table.table_mgr"

local state = {}
state.NONE       = 0
state.START      = 1
state.CREATE     = 2
state.JOIN       = 3
state.READY      = 4
state.SHUFFLE    = 5
state.DICE       = 6
state.DEAL       = 7
state.XUANPAO    = 8
-- state.TAKE_XUANQUE = 9  -- 此状态应该没有用
state.XUANQUE    = 10
state.TAKECARD   = 11
state.TURN       = 12      -- 一定是出牌，但是不一定会拿牌
state.LEAD       = 13

state.MCALL      = 14      -- 一定会自己拿牌
state.OCALL      = 15
state.PENG       = 16
state.GANG       = 17
state.HU         = 18

state.OVER       = 19
state.SETTLE     = 20
state.RESTART    = 21

local cls = class("rcontext")

function cls:ctor()
	-- body
	table_mgr:load()

	-- players
	self._players = {}
	for i=1,4 do
		local tmp = player.new(self, 0, 0)
		tmp._idx = i
		self._players[i] = tmp
	end

	-- room
	self._id = 0
	self._open = false
	self._host = 0
	self._type = 0
	self._mode = 0
	self.create_at = 0
	self.update_at = 0

	-- mahjong rule
	self._local = region.Sichuan
	self._overtype = overtype.XUEZHAN
	self._maxmultiple = 8
	-- self._humultiple = humultiple(self._local, self._maxmultiple)
	self._exist = exist(self._local)
	self._hujiaozhuanyi = false
	self._zimo = 0
	self._dianganghua = 0
	self._daiyaojiu = 0
	self._duanyaojiu = 0
	self._jiangdui = 0
	self._tiandihu = 0
	self._maxju = 0

	-- players
	self._max = 4
	self._joined = 0
	self._online = 0

	-- play
	self._cards = {}         -- 洗牌
	self._cardssz = 108
	self._kcards = {}
	self:init_cards()

	-- gameplay
	self._countdown = 20 -- s
	self._state = state.NONE
	self._laststate = state.NONE

	self._firsttake = 0      -- 拿谁的牌
	self._firstidx  = 0      -- 庄家玩家的索引
	self._curtake   = 0      -- 当前拿谁的牌
	self._curidx    = 0      -- 当前该谁拿
	self._curcard   = nil    -- 此字段应该注释不用
	self._lastidx   = 0      -- last time lead from who
	self._lastcard  = nil    -- last time lead card

	self._takeround = 1      -- deal card count
	self._takepoint = 0

	self._call = {}
	self._callcounter = 0
	self._opinfos = {}

	self._firsthu  = 0    -- next first hu reset
	self._hucount  = 0    -- hu total player
	self._ju = 0
	self._overtimer = nil

	-- record
	self._stime = 0
	self._record = {}
	return self
end

function cls:set_id(value, ... )
	-- body
	self._id = value
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
	if self._joined >= self._max then
		return nil
	end
	for i=1,self._max do
		if self._players[i]._uid == 0 then
			return self._players[i]
		end
	end
end

function cls:get_player_by_uid(uid, ... )
	-- body
	assert(uid)
	for i=1,self._max do
		local p = assert(self._players[i])
		if p._uid == uid then
			return p
		end
	end
	return nil
end

function cls:init_cards( ... )
	-- body
	for i=1,3 do
		for j=1,9 do
			for k=1,4 do
				local cc = card.new(i, j, k)
				table.insert(self._cards, cc)
				self._kcards[cc:get_value()] = cc
			end
		end
	end
end

function cls:clear_state(state, ... )
	-- body
	assert(state)
	for i=1,4 do
		self._players[i]._state = state
	end
end

function cls:check_state(idx, state, ... )
	-- body
	log.info("check player %d state", idx)
	self._players[idx]._state = state
	for i=1,self._max do
		if self._players[i]._state ~= state then
			return false
		end
	end
	return true
end

function cls:push_client(name, args, ... )
	-- body
	for i=1,self._max do
		local p = self._players[i]
		if not p:get_noone() then
			if p:get_online() then
				log.info("push protocol %s to idx %d.", name, i)
				skynet.send(p._agent, "lua", name, args)
			end
		end
	end
end

function cls:push_client_idx(idx, name, args, ... )
	-- body
	assert(idx and name and args)
	local p = self._players[idx]
	if not p:get_noone() and p:get_online() then
		log.info("push protocol %s to idx %d.", name, idx)
		skynet.send(p._agent, "lua", name, args)
	end
end

function cls:push_client_except_idx(idx, name, args, ... )
	-- body
	for i=1,self._max do
		if idx ~= i then
			local p = self._players[i]
			if not p:get_noone() and p:get_online() then
				log.info("push protocol %s to idx %d.", name, i)
				skynet.send(p._agent, "lua", name, args)
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

function cls:next_idx( ... )
	-- body
	self._curidx = self._curidx + 1
	if self._curidx > self._max then
		self._curidx = 1
	end
	return self._curidx
end

function cls:next_takeidx( ... )
	-- body
	self._takepoint = self._takepoint + 1
	self._curtake = self._curtake - 1
	if self._curtake <= 0 then
		self._curtake = self._max
	end
	return self._curtake, self._takepoint
end

function cls:take_card( ... )
	-- body
	local takep = self._players[self._curtake]
	local ok, card = takep:take_card()
	if ok then
		self._curcard = card
		return ok, card
	else
		local takeidx, takepoint = self:next_takeidx()
		if takepoint >= 6 then
			return false
		else
			takep = self._players[takeidx]
			local ok, card = takep:take_card()
			if ok then
				self._curcard = card
				return ok, card
			else
				return false
			end
		end
	end
end

-- 此函数只检测不同地方玩法的由胡的人数觉定是否结束
function cls:check_over( ... )
	-- body
	if self._overtype == overtype.JIEHU then
		local count = 0
		for i=1,self._max do
			if self._players[i]:hashu() then
				count = count + 1
			end
		end
		if count >= 1 then
			return true
		end
	elseif self._overtype == overtype.XUEZHAN then
		local count = 0
		for i=1,self._max do
			if self._players[i]:hashu() then
				count = count + 1
			end
		end
		if count >= 3 then
			return true
		end
	elseif self._overtype == overtype.XUELIU then
		return false
	end
	return false
end

------------------------------------------
-- 服务协议
function cls:start()
	-- body
	assert(self)
	return true
end

function cls:init_data()
	-- body
	local pack = skynet.call('.DB', "lua", "read_room", self._id)
	-- 初始所有房间数据
	local db_room = pack.db_rooms[1]
	local open = db_room.open
	if not open then
		return true
	end
	if db_room.type ~= 1 then
		return true
	end
	self._type = db_room.type
	self._mode = db_room.mode
	self._host = db_room.host
	self._open = db_room.open
	self.create_at = assert(db_room.create_at)
	self.update_at = assert(db_room.update_at)
	local rule = json.decode(db_room.rule)
	self._local = rule['local']
	self._overtype = rule.overtype
	self._maxmultiple = rule.maxmultiple
	self._hujiaozhuanyi = rule.hujiaozhuanyi
	self._zimo = rule.zimo
	self._dianganghua = rule.dianganghua
	self._daiyaojiu = rule.daiyaojiu
	self._duanyaojiu = rule.duanyaojiu
	self._jiangdui = rule.jiangdui
	self._tiandihu = rule.tiandihu
	self._maxju = rule.maxju

	-- 初始加入此房间玩家数据
	local db_users = pack.db_users
	for _,db_user in pairs(db_users) do
		local player = self._players[db_user.idx]
		player._uid = db_user.uid
		player._idx = db_user.idx
		player._chip = db_user.chip
		player._state = db_user.state
		player._laststate = db_user.last_state
		player._que = db_user.que
		self._joined = self._joined + 1
	end
	assert(self._online == 0)
	if self._joined >= self._max then
		self._state = state.JOIN
	end
	return true
end

function cls:sayhi(type, mode, host, users)
	-- body
	assert(type)
	if self._open and self._type == 1 then
		assert(self._type == type)
		assert(self._mode == mode)
		assert(self._host == host)
	else
		self._type = type
		self._mode = mode
		self._host = host	
	end
	skynet.call('.CHAT_MGR', 'lua', 'room_create', self._id, skynet.self())
	return true
end

function cls:save_data()
	-- body
	if not self._open then
		-- log.error("roomid = %d, save_data self._open is false", self._id)
		return
	end
	-- 创建类房间存数据
	if self._type == 1 then
		-- 存储房间数据
		local db_room = {}
		db_room.id   = assert(self._id)
		db_room.type = self._type
		db_room.mode = self._mode
		db_room.host = assert(self._host)
		db_room.open = assert(self._open) and 1 or 0
		if not self.create_at then
			db_room.create_at = os.time()
		else
			db_room.create_at = assert(self.create_at)
		end
		db_room.update_at = os.time()
		local rule = {}
		rule['local'] = self._local
		rule.overtype = self._overtype
		rule.maxmultiple = self._maxmultiple
		rule.hujiaozhuanyi = self._hujiaozhuanyi
		rule.zimo = self._zimo
		rule.dianganghua = self._dianganghua
		rule.daiyaojiu = self._daiyaojiu
		rule.duanyaojiu = self._duanyaojiu
		rule.jiangdui = self._jiangdui
		rule.tiandihu = self._tiandihu
		rule.maxju = self._maxju
		db_room.rule = json.encode(rule)

		-- 存储玩家数据
		local db_users = {}
		for k,v in pairs(self._players) do
			if v._uid > 0 then      -- > 0 才是有人加入
				local db_user = {}
				db_user.uid = assert(v._uid)
				db_user.roomid = self._id
				db_user.idx = assert(v._idx)
				db_user.chip = assert(v._chip)
				db_user.state = assert(v._state)
				-- 下面数据暂时不用
				-- db_user.last_state   = assert(v._laststate)
				-- db_user.que          = assert(v._que)
				-- db_user.takecardsidx = assert(v._takecardsidx)
				-- db_user.takecardscnt = assert(v._takecardscnt)
				-- db_user.takecardslen = assert(v._takecardslen)
				-- db_user.takecards = {}
				-- for pos,card in pairs(v._takecards) do
				-- 	db_user.takecards[string.format("%d", pos)] = card:get_value()
				-- end
				-- db_user.cards = {}
				-- for pos,card in pairs(v._cards) do
				-- 	db_user.cards[string.format("%d", pos)] = card:get_value()
				-- end
				-- db_user.leadcards = {}
				-- for pos,card in pairs(v._leadcards) do
				-- 	db_user.leadcards[string.format("%d", pos)] = card:get_value()
				-- end
				-- db_user.putcards = {}
				-- for pos,card in pairs(v._putcards) do
				-- 	db_user.putcards[string.format("%d", pos)] = card:get_value()
				-- end
				-- db_user.putidx = assert(v._putidx)
				-- if v._holdcard then
				-- 	db_user.holdcard = assert(v._holdcard:get_value())
				-- end
				-- db_user.hucards = {}
				-- for pos,card in pairs(v._hucards) do
				-- 	db_user.hucards[string.format("%d", pos)] = card:get_value()
				-- end
				db_users[string.format("%d", k)] = db_user
			end
		end

		local pack = {}
		pack.db_room = db_room
		pack.db_users = db_users

		skynet.call(".DB", "lua", "write_room", pack)
	end
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
	-- 自建房间
	self._type = 1
	self._host = uid
	self._open = true
	if args.provice == region.Sichuan then
		self._local = region.Sichuan
		self._overtype = args.overtype
		self._maxmultiple = args.sc.top
		self._hujiaozhuanyi = args.sc.hujiaozhuanyi
		-- self._humultiple = humultiple(self._local, self._maxmultiple)
		self._exist = exist(self._local)
		self._maxju = args.ju

	elseif args.provice == region.Shaanxi then
		self._local = region.Shaanxi
		self._overtype = args.overtype
		self._maxmultiple = -1
		self._hujiaozhuanyi = false
		-- self._humultiple = humultiple(self._local, self._maxmultiple)
		self._exist = exist(self._local)
		self._maxju = args.ju
	end

	-- clear player
	for i=1,4 do
		self._players[i]:set_noone(true)
		self._players[i]:set_online(false)
	end
	self._joined = 0
	self._online = 0

	self:clear()

	self._stime = 0
	self._record = {}
	self._ju = 0

	self._state = state.JOIN
	local res = {}
	res.errorcode = 0
	res.roomid = self._id
	res.mode   = self._mode
	res.room_max = self._max
	return res
end

function cls:join(uid, agent, name, sex)
	-- body
	assert(uid and agent and name and sex)
	local res = {}
	if self._state ~= state.JOIN then
		res.errorcode = 15
		return res
	end

	if self._joined >= self._max then
		res.errorcode = 16
		return res
	end

	-- 原来肯定是不存在此用户
	local p = self:get_player_by_uid(uid)
	assert(p == nil)

	local me = assert(self:find_noone())
	me:set_uid(uid)
	me:set_agent(agent)
	me:set_name(name)
	me:set_sex(sex)
	me:set_online(true)

	self._joined = self._joined + 1
	self._online = self._online + 1

	if self._joined >= self._max then
		self._state = state.READY
		self:clear_state(player.state.WAIT_READY)
	end

	-- sync
	local p = {
		idx   =  me._idx,
		chip  =  me._chip,
		sex   =  me._sex,
		name  =  me._name,
		state =  me._state,
		last_state   = me._laststate,
		que          = me._que,
		takecardsidx = me._takecardsidx,
		takecardscnt = me._takecardscnt,
		takecardslen = me._takecardslen,
		takecards    = me:pack_takecards(),
		cards        = me:pack_cards(),
		leadcards    = me:pack_leadcards(),
		putcards     = me:pack_putcards(),
		putidx       = me._putidx,
		hold_card    = me:pack_holdcard(),
		hucards      = me:pack_hucards(),
		online       = me._online
	}

	res.errorcode = 0
	res.roomid = self._id
	res.room_max = self._max
	res.mode = self._mode
	res.type = self._type
	res.state = self._state
	res.me = p
	res.ps = {}
	for _,v in ipairs(self._players) do
		if not v:get_noone() and v:get_uid() ~= uid then
			local p = {
				idx   =  v._idx,
				chip  =  v._chip,
				sex   =  v._sex,
				name  =  v._name,
				state =  v._state,
				last_state   = v._laststate,
				que          = v._que,
				takecardsidx = v._takecardsidx,
				takecardscnt = v._takecardscnt,
				takecardslen = v._takecardslen,
				takecards    = v:pack_takecards(),
				cards        = v:pack_cards(),
				leadcards    = v:pack_leadcards(),
				putcards     = v:pack_putcards(),
				putidx       = v._putidx,
				hold_card    = v:pack_holdcard(),
				hucards      = v:pack_hucards(),
				online       = v._online
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me:get_idx(), "join", args)

	-- 推动准备
	if self._online >= self._max then
		self:take_ready()
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

	assert(not me:get_online())
	me:set_agent(agent)
	me:set_online(true)
	self._online = self._online + 1

	-- sync
	local p = {
		idx   =  me._idx,
		chip  =  me._chip,
		sex   =  me._sex,
		name  =  me._name,
		state =  me._state,
		last_state   = me._laststate,
		que          = me._que,
		takecardsidx = me._takecardsidx,
		takecardscnt = me._takecardscnt,
		takecardslen = me._takecardslen,
		takecards    = me:pack_takecards(),
		cards        = me:pack_cards(),
		leadcards    = me:pack_leadcards(),
		putcards     = me:pack_putcards(),
		putidx       = me._putidx,
		hold_card    = me:pack_holdcard(),
		hucards      = me:pack_hucards(),
		online       = me._online
	}

	res.errorcode = 0
	res.roomid = self._id
	res.room_max = self._max
	res.state = self._state
	res.me = p
	res.ps = {}
	for _,v in ipairs(self._players) do
		if not v:get_noone() and v:get_uid() ~= uid then
			local p = {
				idx   =  v._idx,
				chip  =  v._chip,
				sex   =  v._sex,
				name  =  v._name,
				state =  v._state,
				last_state   = v._laststate,
				que          = v._que,
				takecardsidx = v._takecardsidx,
				takecardscnt = v._takecardscnt,
				takecardslen = v._takecardslen,
				takecards    = v:pack_takecards(),
				cards        = v:pack_cards(),
				leadcards    = v:pack_leadcards(),
				putcards     = v:pack_putcards(),
				putidx       = v._putidx,
				hold_card    = v:pack_holdcard(),
				hucards      = v:pack_hucards(),
				online       = v._online
			}
			table.insert(res.ps, p)
		end
	end
	skynet.retpack(res)

	local args = {}
	args.p = p
	self:push_client_except_idx(me:get_idx(), "rejoin", args)

	if self._state == state.JOIN then
		if self._online >= self._max then
			self:take_ready()
		end
	end
	return servicecode.NORET
end

function cls:afk(uid)
	-- body
	log.info('roomid = %d, uid(%d) afk', self._id, uid)
	local p = self:get_player_by_uid(uid)
	assert(p)
	p:set_online(false)
	self._online = self._online - 1
	self._state = state.JOIN

	local args = {}
	args.idx = p:get_idx()
	self:push_client_except_idx(p:get_idx(), "offline", args)
	return true
end

function cls:leave(uid)
	-- body
	local p = self:get_player_by_uid(uid)
	assert(p)
	local idx = p:get_idx()
	p:set_online(false)
	p:set_uid(0)
	self._online = self._online - 1
	self._joined = self._joined - 1
	self._state = state.JOIN
	local res = {}
	res.errorcode = 0
	skynet.retpack(res)

	local args = {}
	args.idx = idx
	self:push_client_except_idx(idx, "leave", args)
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
-- 麻将协议
function cls:step(idx, ... )
	-- body
	assert(idx)
	local res = {}
	if not self._open then
		res.errorcode = errorcode.FAIL
		return res
	end
	if self._joined ~= self._max or self._online ~= self._max then
		res.errorcode = errorcode.FAIL
		return res
	end
	log.info("self._laststate = %d, self._state = %d", self._laststate, self._state)
	if self._state == state.JOIN then
		log.warning("step wrong state JOIN")
		res.errorcode = errorcode.FAIL
		return res
	elseif self._state == state.READY then
		log.warning("step wrong state READY")
		res.errorcode = errorcode.FAIL
		return res
	elseif self._state == state.SHUFFLE then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.SHUFFLE) then
			self:take_dice()
		end
	elseif self._state == state.DICE then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.DICE) then
			self:take_deal()
		end
	elseif self._state == state.DEAL then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.DEAL) then
			if self._local == region.Sichuan then
				self:take_xuanque()
			else
				if self:take_mcall() then
				else
					self:take_turn()
				end
			end
		end
	elseif self._state == state.XUANQUE then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.XUANQUE) then
			self:take_turn()
		end
	elseif self._state == state.TAKECARD then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.TAKECARD) then
			if not self:take_mcall() then
				self:take_turn()
			end
		end
	elseif self._state == state.LEAD then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.LEAD) then
			if not self:take_ocall() then
				self:_next()
			end
		end
	elseif self._state == state.PENG then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.PENG) then
			self:take_turn()
		end
	elseif self._state == state.GANG then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.GANG) then
			local cs = self._call[self._curidx]
			assert(cs)
			if (cs.opcode & opcode.gang > 0) and cs.gangtype == gangtype.bugang then
				if not self:take_ocall() then
					self:take_takecard()
				end
			else
				self:take_takecard()
			end
		end
	elseif self._state == state.HU then
		local p = self._players[idx]
		assert(not p:get_noone() and p:get_online())
		if self:check_state(idx, player.state.HU) then
			self:_next()
		end
	elseif self._state == state.OVER then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.OVER) then
			self:take_settle()
		end
	end
	res.errorcode = errorcode.SUCCESS
	return res
end

function cls:ready(idx, ... )
	-- body
	local res = {}
	if not self._open then
		res.errorcode = errorcode.FAIL 
		return res
	end
	if self._state ~= state.READY then
		res.errorcode = errorcode.WRONG_STATE
		res.idx = idx
		return res
	end
	if self._players[idx]._state ~= player.state.WAIT_READY then
		res.errorcode = errorcode.WRONG_STATE
		res.idx = idx
		return res
	end
	if self:check_state(idx, player.state.READY) then
		for i=1,self._max do
			self._players[i]:clear()
		end
		self:take_shuffle()
	end
	res.errorcode = 0
	res.idx = idx
	return res
end

function cls:xuanpao(args, ... )
	-- body
	assert(self._state == state.XUANPAO)
	self._players[args.idx]:set_fen(args.fen)
	self:record("take_xuanpao")
	self:push_client("xuanpao", args)
	if self:check_state(idx, player.state.WAIT_TURN) then
		self._curidx = self._firstidx -- reset curidx for turn 
		self._curcard = self:take_card()
		if self:take_mcall() then
		else
			self:take_turn()
		end
	end
end

function cls:xuanque(args, ... )
	-- body
	local res = {}
	if not self._open then
		res.errorcode = errorcode.FAIL
		return res
	end
	if self._state == state.TAKE_XUANQUE then
		if self._players[args.idx]._state == player.state.WAIT_TAKE_XUANQUE then
			self._players[args.idx]:cancel_timeout()
			self._players[args.idx]:set_que(args.que)
			if self:check_state(args.idx, player.TAKE_XUANQUE) then
				self._state = state.XUANQUE
				self:clear_state(player.state.WAIT_XUANQUE)
				local args = {}
				args.p1 = self._players[1]:get_que()
				args.p2 = self._players[2]:get_que()
				args.p3 = self._players[3]:get_que()
				args.p4 = self._players[4]:get_que()
				self:record("xuanque", args)
				self:push_client("xuanque", args)
			end
		else
			res.errorcode = errorcode.WRONG_STATE
			return res
		end
	else
		res.errorcode = errorcode.WRONG_STATE
		return res
	end
end

function cls:timeout_xuanque(args, ... )
	-- body
	if self._state == state.TAKE_XUANQUE then
		if self._players[args.idx]._state == player.state.WAIT_TAKE_XUANQUE then
			self._players[args.idx]:set_que(args.que)
			if self:check_state(args.idx, player.TAKE_XUANQUE) then
				self._state = state.XUANQUE
				self:clear_state(player.state.WAIT_XUANQUE)
				local args = {}
				args.p1 = self._players[1]:get_que()
				args.p2 = self._players[2]:get_que()
				args.p3 = self._players[3]:get_que()
				args.p4 = self._players[4]:get_que()
				self:record("xuanque", args)
				self:push_client("xuanque", args)
			end
		end	
	end
end

-- @breif
-- @return 
-- errorcode: 
function cls:lead(idx, c, isHoldcard, ... )
	-- body
	assert(idx and c)
	local res = {}
	if not self._open then
		res.errorcode = errorcode.NOT_OPEND
		return res
	end
	if idx ~= self._curidx then
		res.errorcode = errorcode.WRONG_IDX
		return res
	end
	if self._state == state.TURN then
		assert(self._players[idx]:get_state() == player.state.WAIT_TURN)
		self._players[idx]:cancel_timeout()

		local ok, card = self._players[idx]:lead(c, isHoldcard)
		if not ok then
			res.errorcode = 3
			return res
		end
		assert(card:get_value() == c)
		log.info("player %d lead %s", idx, card:describe())
		
		self._state = state.LEAD
		self:clear_state(player.state.WAIT_LEAD)

		self._lastidx = idx
		self._lastcard = card
		
		local args = {}
		args.idx = idx
		args.card = c
		args.isHoldcard = isHoldcard

		self:record("lead", args)
		self:push_client("lead", args)

		res.errorcode = errorcode.SUCCESS
		return res
	else
		log.info("player %d has leaded", idx)
		res.errorcode = errorcode.WRONG_STATE
		return res
	end
end

function cls:peng(penginfo, ... )
	-- body
	log.info("player peng")
	assert(penginfo)
	local res = {}
	if not self._open then
		log.error("not open")
		res.errorcode = errorcode.FAIL
		return res
	end
	if self._state == state.OCALL then
		self._state = state.PENG
		self:clear_state(player.state.WAIT_PENG)

		assert(penginfo.idx ~= self._curidx)
		self._curidx = penginfo.idx
		local res = self._players[penginfo.idx]:peng(penginfo, self._players[self._lastidx], self._lastcard)
		penginfo.hor = res.hor

		self:record("peng", penginfo)
		self:push_client("peng", penginfo)

		res.errorcode = errorcode.SUCCESS
		return res
	else
		res.errorcode = errorcode.WRONG_STATE
		return res
	end
end

function cls:gang(ganginfo, ... )
	-- body
	assert(ganginfo)
	local res = {}
	if not self._open then
		res.errorcode = errorcode.FAIL
		return res
	end
	if self._state == state.MCALL then
		assert(ganginfo.idx == self._curidx)
		self._state = state.GANG
		self:clear_state(player.state.WAIT_GANG)
		if ganginfo.code == opcode.bugang then
			local dianPlayer = self._players[ganginfo.dian]
			self._players[ganginfo.idx]:gang(ganginfo.gangtype, dianPlayer, ganginfo.originalCard)
			local base = gangmultiple(ganginfo.ganginfo)

			local total = 0
			local lose = {}
			local win = {ganginfo.idx}
			local settle = {}
			for i=1,self._max do
				if i == ganginfo.idx then
				elseif self._players[i]:hashu() then
				else
					total = total + base
					table.insert(lose, i)

					local cnode = {}
					cnode.idx  = i
					cnode.chip = -base
					cnode.them = win
					cnode.opcode = opcode.gang
					cnode.gangtype = gangtype.bugang
					cnode.huazhu = false
					cnode.dajiao = false
					cnode.tuisui = false

					self:insert_settle(settle, cnode.idx, cnode)
					self._players[i]:record_settle(cnode)
				end
			end

			local cnode = {}
			cnode.idx  = ganginfo.idx
			cnode.chip = total
			cnode.them = lose
			cnode.opcode = opcode.gang
			cnode.gangtype = gangtype.bugang
			cnode.huazhu = false
			cnode.dajiao = false
			cnode.tuisui = false

			self:insert_settle(settle, cnode.idx, cnode)
			self._players[ganginfo.idx]:record_settle(cnode)

			local settles = {}
			table.insert(settles, settle)
			local args = {}
			args.idx = ganginfo.idx
			args.code = ganginfo.opcode
			args.card = ganginfo.card
			args.hor = ganginfo.hor
			args.dian = ganginfo.dian
			args.settles = settles

			self:record("gang", args)
			self:push_client("gang", args)

			res.errorcode = errorcode.SUCCESS
		elseif ganginfo.code == opcode.angang then
			self._players[ganginfo.idx]:gang(ganginfo, self._players[self._lastidx], self._lastcard)
			local base = gangmultiple(opcode.angang)
			local total = 0
			local lose = {}
			local win = {ganginfo.idx}
			local settle = {}
			for i=1,self._max do
				if i == ganginfo.idx then
				elseif self._players[i]:hashu() then
				else
					total = total + base
					table.insert(lose, i)

					local cnode = {}
					cnode.idx  = i
					cnode.chip = -base
					cnode.left = self._players[i]:settle(cnode.chip)

					cnode.win  = win
					cnode.lose = lose
					cnode.gang = ganginfo.code
					cnode.hucode = hutype.NONE
					cnode.huazhu = 0
					cnode.dajiao = 0
					cnode.tuisui = 0

					self:insert_settle(settle, cnode.idx, cnode)
					self._players[i]:record_settle(cnode)
				end
			end

			local cnode = {}
			cnode.idx  = ganginfo.idx
			cnode.chip = total
			cnode.left = self._players[ganginfo.idx]:settle(cnode.chip)

			cnode.win  = win
			cnode.lose = lose

			cnode.gang = ganginfo.code
			cnode.hucode = hutype.NONE
			cnode.huazhu = 0
			cnode.dajiao = 0
			cnode.tuisui = 0

			self:insert_settle(settle, cnode.idx, cnode)
			self._players[ganginfo.idx]:record_settle(cnode)

			local settles = {}
			table.insert(settles, settle)

			ganginfo.settles = settles
			self:record("gang", ganginfo)
			self:push_client("gang", ganginfo)

			res.errorcode = errorcode.SUCCESS
			return res
		else
			res.errorcode = errorcode.WRONG_STATE
			return res
		end
	elseif self._state == state.OCALL then
		self._state = state.GANG
		self:clear_state(player.state.WAIT_GANG)
		if ganginfo.code == opcode.zhigang then
			assert(self._curidx ~= ganginfo.idx)
			self._curidx = ganginfo.idx
			local res = self._players[ganginfo.idx]:gang(ganginfo, self._players[self._lastidx], self._lastcard)
			ganginfo.hor = res.hor

			local settle = {}
			local base = gangmultiple(opcode.zhigang)
			local win = {ganginfo.idx}
			local lose = {self._lastidx}
			
			local wnode = {}
			wnode.idx  = ganginfo.idx
			wnode.chip = base
			wnode.left = self._players[wnode.idx]:settle(wnode.chip)

			wnode.win  = win
			wnode.lose = lose
			wnode.gang = ganginfo.code
			wnode.hucode = hutype.NONE
			wnode.huazhu = 0
			wnode.dajiao = 0
			wnode.tuisui = 0

			self:insert_settle(settle, wnode.idx, wnode)
			self._players[ganginfo.idx]:record_settle(wnode)

			local lnode = {}
			lnode.idx  = self._lastidx
			lnode.chip = -base
			lnode.left = self._players[self._lastidx]:settle(lnode.chip)

			lnode.win  = win
			lnode.lose = lose
			lnode.gang = ganginfo.code
			lnode.hucode = hutype.NONE
			lnode.huazhu = 0
			lnode.dajiao = 0
			lnode.tuisui = 0
			
			self:insert_settle(settle, lnode.idx, lnode)
			self._players[self._lastidx]:record_settle(lnode)
			
			local settles = {}
			table.insert(settles, settle)
			ganginfo.settles = settles
			self:record("gang", ganginfo)
			self:push_client("gang", ganginfo)
		else
			assert(false)
		end
	else
		assert(false)
	end
end

function cls:check_firsthu(idx, ... )
	-- body
	assert(idx and idx > 0 and idx <= self._max)
	local count = 0
	for i=1,self._max do
		if self._players[i]:hashu() then
			count = count + 1
		end
	end
	if count == 1 then
		self._lastfirsthu = idx
	end
end

function cls:hu(hus, ... )
	-- body
	assert(hus)
	local res = {}
	if not self._open then
		res.errorcode = errorcode.FAIL
		return res
	end
	if self._state == state.MCALL then
		assert(#hus == 1)
		local huinfo = hus[1]
		self._state = state.HU
		self._players[self._curidx]:hu(huinfo, self._players[self._curidx], self._curcard)
		self:check_firsthu(self._curidx)
		
		local settle = {}
		local win = {}
		local lose = {}
		if huinfo.jiao == jiaotype.DIANGANGHUA then
			local base = self._humultiple(huinfo.code, huinfo.jiao, huinfo.gang)
			if self._dianganghua == 0 then
				table.insert(win, huinfo.idx)
				table.insert(lose, huinfo.dian)
				local wnode = {}
				wnode.idx  = huinfo.idx
				wnode.chip = base
				wnode.left = self._players[self._curidx]:settle(wnode.chip)

				wnode.win  = win
				wnode.lose = lose
				wnode.gang = opcode.none
				wnode.hucode = huinfo.code
				wnode.hujiao = huinfo.jiao
				wnode.hugang = huinfo.gang
				wnode.huazhu = 0
				wnode.dajiao = 0
				wnode.tuisui = 0
				self:insert_settle(settle, wnode.idx, wnode)
				self._players[self._curidx]:record_settle(wnode)

				local lnode = {}
				lnode.idx  = self._lastidx
				lnode.chip = -base
				lnode.left = settle._players[self._lastidx]:settle(wnode.chip)

				lnode.win  = win
				lnode.lose = lose
				lnode.gang = opcode.none
				lnode.hucode = huinfo.code
				lnode.hujiao = huinfo.jiao
				lnode.hugang = huinfo.gang
				lnode.huazhu = 0
				lnode.dajiao = 0
				lnode.tuisui = 0
				self:insert_settle(settle, lnode.idx, lnode)
				self._players[self._lastidx]:record_settle(lnode)
			else
				local total = 0
				table.insert(win, huinfo.idx)
				for i=1,self._max do
					if i == self._curidx then
					elseif self._players[i]:hashu() then
					else
						total = total + base
						table.insert(lose, i)
						local node = {}
						node.idx  = i
						node.chip = -base
						node.left = self._players[i]:settle(node.chip)

						node.win  = win
						node.lose = lose
						node.gang = opcode.none
						node.hucode = huinfo.code
						node.hujiao = huinfo.jiao
						node.hugang = huinfo.gang
						node.huazhu = 0
						node.dajiao = 0
						node.tuisui = 0
						self:insert_settle(settle, node.idx, node)
						self._players[i]:record_settle(node)
					end
				end
				local wnode = {}
				wnode.idx  = self._curidx
				wnode.chip = total
				wnode.left = self._players[self._curidx]:settle(wnode.chip)

				wnode.win  = win
				wnode.lose = lose
				wnode.gang = opcode.none
				wnode.hucode = huinfo.code
				wnode.hujiao = huinfo.jiao
				wnode.hugang = huinfo.gang
				wnode.huazhu = 0
				wnode.dajiao = 0
				wnode.tuisui = 0
				self:insert_settle(settle, wnode.idx, wnode)
				self._players[self._curidx]:record_settle(wnode)
			end
		elseif huinfo.jiao == jiaotype.ZIMO or
			huinfo.jiao == jiaotype.ZIGANGHUA then
			
			local base = self._humultiple(huinfo.code, huinfo.jiao, huinfo.gang)
			local total = 0
			local lose = {}
			local win = {huinfo.idx}
			for i=1,self._max do
				if i == self._curidx then
				elseif self._players[i]:hashu() then
				else
					total = total + base
					table.insert(lose, i)
					local node = {}
					node.idx  = i
					node.chip = -base
					node.left = self._players[i]:settle(node.chip)

					node.win  = win
					node.lose = lose
					node.gang = opcode.none
					node.hucode = huinfo.code
					node.hujiao = huinfo.jiao
					node.hugang = huinfo.gang
					node.huazhu = 0
					node.dajiao = 0
					node.tuisui = 0

					self:insert_settle(settle, node.idx, node)
					self._players[i]:record_settle(node)
				end
			end
			local wnode = {}
			wnode.idx  = self._curidx
			wnode.chip = total
			wnode.left = self._players[self._curidx]:settle(wnode.chip)

			wnode.win  = win
			wnode.lose = lose
			wnode.gang = opcode.none
			wnode.hucode = huinfo.code
			wnode.hujiao = huinfo.jiao
			wnode.hugang = huinfo.gang
			wnode.huazhu = 0
			wnode.dajiao = 0
			wnode.tuisui = 0

			self:insert_settle(settle, wnode.idx, wnode)
			self._players[self._curidx]:record_settle(wnode)
		else
			assert(false)
		end

		local settles = {}
		table.insert(settles, settle)

		local args = {}
		args.hus = hus
		args.settles = settles

		self:record("hu", args)
		self:push_client("hu", args)
	elseif self._state == state.OCALL then
		self._state = state.HU

		local settles = {}
		local count = 0
		local idx = self._curidx
		for i=1,self._max do
			local j = idx + i
			if j > self._max then
				j = j - self._max
			end
			for k,v in pairs(hus) do
				if v.idx == j then
					count = count + 1
					self._curidx = j

					local huinfo = self._players[v.idx]:hu(v, self._players[self._lastidx], self._lastcard)
					if v.jiao == jiaotype.QIANGGANGHU then
						-- tuisui
						local settle = {}
						self._players[huinfo.dian]:tuisui_with_qianggang(settle)
						table.insert(settles, settle)
					end
					local win = {huinfo.idx}
					local lose = {huinfo.dian}
					local settle = {}

					table.insert(win, v.idx)
					local base = self._humultiple(huinfo.code, huinfo.jiao, huinfo.gang)

					local wnode = {}
					wnode.idx  = huinfo.idx
					wnode.chip = base
					wnode.left = self._players[wnode.idx]:settle(wnode.chip)

					wnode.win  = win
					wnode.lose = lose
					wnode.gang = opcode.none
					wnode.hucode = huinfo.code
					wnode.hujiao = huinfo.jiao
					wnode.hugang = huinfo.gang
					wnode.huazhu = 0
					wnode.dajiao = 0
					wnode.tuisui = 0
					self:insert_settle(settle, wnode.idx, wnode)
					self._players[wnode.idx]:record_settle(wnode)
					
					local lnode = {}
					lnode.idx  = huinfo.dian
					lnode.chip = -base
					lnode.left = self._players[lnode.idx]:settle(lnode.chip)

					lnode.win  = win
					lnode.lose = lose
					lnode.gang = opcode.none
					lnode.hucode = huinfo.code
					lnode.hujiao = huinfo.jiao
					lnode.hugang = huinfo.gang
					lnode.huazhu = 0
					lnode.dajiao = 0
					lnode.tuisui = 0

					self:insert_settle(settle, lnode.idx, lnode)
					self._players[lnode.idx]:record_settle(lnode)

					table.insert(settles, settle)			
					break
				end
			end
			if count == #hus then
				break
			end
		end
		
		if #hus > 1 then
			self._lastwin = self._lastidx
		else
			self._lastwin = self._curidx
		end

		local args = {}
		args.hus = hus
		args.settles = settles
		self:push_client("hu", args)
	else
		assert(false)
	end
end

function cls:_next( ... )
	-- body
	if self:check_over() then
		self:take_over()
	else
		self:next_idx()
		self:take_takecard()
	end
end

function cls:mcall(opinfo, ... )
	-- body
	local idx = opinfo.idx
	local code = opinfo.opcode
	local call = self._call[idx]
	if code == opcode.gang then
		self:gang(call)
	elseif code == opcode.hu then
		local hus = {}
		table.insert(hus, call)
		self:hu(hus)
	else
		self:take_turn()
	end
	local res = {}
	res.errorcode = errorcode.SUCCESS
	return res
end

function cls:call(opinfo, ... )
	-- body
	if self._state == state.MCALL then
		return self:mcall(opinfo)		
	elseif self._state == state.OCALL then
		assert(self._opinfos[opinfo.idx] == nil)
		self._opinfos[opinfo.idx] = opinfo
		self._callcounter = self._callcounter - 1
		if self._callcounter <= 0 then
			local hu = {}
			local husz = 0
			local gang = {}
			local gangsz = 0
			local peng = {}
			local pengsz = 0
			for k,v in pairs(self._opinfos) do
				if v.opcode == opcode.hu then
					hu[k] = v
					husz = husz + 1
				elseif v.opcode == opcode.gang then
					gang[k] = v
					gangsz = gangsz + 1
				elseif v.opcode ==opcode.peng then
					peng[k] = v
					pengsz = pengsz + 1
				end
			end

			if husz > 0 then
				local hus = {}
				for k,v in pairs(hu) do
					local opinfo = self._opinfos[k]
					hus[k] = opinfo
				end
				self:hu(hus)
			elseif gangsz > 0 then
				assert(gangsz == 1)
				local call = 1
				for k,v in pairs(self._opinfos) do
					local call = self._call[k]
				end
				return self:gang(call)
			elseif pengsz > 0 then
				assert(pengsz == 1)
				for k,v in pairs(self._opinfos) do
					local call = self._call[k]
				end
				return self:peng(call)
			else
				self:_next()
				local res = {}
				res.errorcode = errorcode.SUCCESS
				return res
			end
		else
			local res = {}
			res.errorcode = errorcode.SUCCESS
			return res		
		end
	else
		local res = {}
		res.errorcode = errorcode.SUCCESS
		return res	
	end
end

function cls:timeout_call(opinfo, ... )
	-- body
	self:call(opinfo)
end

function cls:restart(idx, ... )
	-- body
	if self._state == state.FINAL_SETTLE then
		local p = self._players[idx]
		assert(not p:get_noone())
		if self:check_state(idx, player.state.WAIT_RESTART) then
			self:take_restart()
		else
			local args = {}
			args.idx = idx
			self:push_client("restart", args)
		end
	end
end

function cls:timeout_restart(idx, ... )
	-- body
end

------------------------------------------
-- turn state
function cls:take_ready()
	if self._state == state.JOIN then
		self._laststate = self._state
		self._state = state.READY	
		self:clear_state(player.state.WAIT_READY)
		self:push_client("take_ready", {})
	end
end

function cls:take_shuffle( ... )
	-- body
	if self._state == state.READY then
		self._state = state.SHUFFLE
		self:clear_state(player.state.WAIT_SHUFFLE)

		self._ju = self._ju + 1
		if self._ju == 1 then
			-- send agent 
			local p = self:get_player_by_uid(self._host)
			local addr = p:get_agent()
			local ok = skynet.call(addr, "lua", "alter_rcard", -1)
			assert(ok)
		end

		self._stime = skynet.now()
		self._record = {}
		-- record 
		local args = {}
		for i=1,self._max do
			local p = {}
			p.idx = self._players[i]:get_idx()
			p.uid = self._players[i]:get_uid()
			table.insert(args, p)
		end
		self:record("players", args)

		if self._ju == 1 then
			self._firstidx = self:get_player_by_uid(self._host):get_idx()
		else
			self._firstidx = self._lastfirsthu
		end
		self._curidx = self._firstidx

		for i=1,self._cardssz do
			self._cards[i]:clear()
		end

		assert(#self._cards == 108)
		for i=107,1,-1 do
			local swp = math.floor(math.random(1, 1000)) % 108 + 1
			while swp == i do
				swp = math.floor(math.random(1, 1000)) % 108 + 1
			end
			local tmp = assert(self._cards[i])
			self._cards[i] = assert(self._cards[swp], swp)
			self._cards[swp] = tmp
		end
		assert(#self._cards == 108)

		local p1 = {}
		for i=1,28 do
			local card = assert(self._cards[i])
			self._players[1]._takecards[i] = card
			table.insert(p1, card:get_value())
		end
		self._players[1]._takecardsidx = 1
		self._players[1]._takecardslen = 28
		self._players[1]._takecardscnt = 28
		assert(#p1 == 28)
		local p2 = {}
		for i=1,28 do
			local card = assert(self._cards[28 + i])
			self._players[2]._takecards[i] = card
			table.insert(p2, card:get_value())
		end
		self._players[2]._takecardsidx = 1
		self._players[2]._takecardslen = 28
		self._players[2]._takecardscnt = 28
		assert(#p2 == 28)
		local p3 = {}
		for i=1,26 do
			local card = assert(self._cards[28*2 + i])
			self._players[3]._takecards[i] = card
			table.insert(p3, card:get_value())
		end
		self._players[3]._takecardsidx = 1
		self._players[3]._takecardslen = 26
		self._players[3]._takecardscnt = 26
		assert(#p3 == 26)
		local p4 = {}
		for i=1,26 do
			local card = assert(self._cards[28*2 + 26 + i])
			self._players[4]._takecards[i] = card
			table.insert(p4, card:get_value())
		end
		self._players[4]._takecardsidx = 1
		self._players[4]._takecardslen = 26
		self._players[4]._takecardscnt = 26
		assert(#p4 == 26)
		local args = {}
		args.p1 = p1
		args.p2 = p2
		args.p3 = p3
		args.p4 = p4
		args.first = self._firstidx

		self:record("shuffle", args)
		self:push_client("shuffle", args)
	else
		log.error('take shuffele state is wrong.')
	end
end

-- 选咆阶段在此阶段没有设计
function cls:take_xuanpao( ... )
	-- body
	self._state = state.XUANPAO
	self:clear_state(player.state.XUANPAO)
	self:record("take_xuanpao")
	self:push_client("take_xuanpao")
end

function cls:take_dice( ... )
	-- body
	self._state = state.DICE
	self:clear_state(player.state.WAIT_DICE)

	local d1 = math.random(0, 5) + 1
	local d2 = math.random(0, 5) + 1
	local min = math.min(d1, d2)
	local point = d1 + d2
	while point > self._max do
		point = point - self._max
	end
	assert(point > 0 and point <= self._max)

	self._firsttake = point
	self._curtake   = point

	self._takeround = 1
	local takep = self._players[self._curtake]
	takep._takecardsidx = (min * 2 + 1)

	local args = {}
	args.first     = self._firstidx
	args.firsttake = self._firsttake
	args.d1 = d1
	args.d2 = d2

	self:record("dice", args)
	self:push_client("dice", args)
end

function cls:take_deal( ... )
	-- body
	self._laststate = self._state
	self._state = state.DEAL
	self:clear_state(player.state.WAIT_DEAL)

	for i=1,4 do
		for j=1,4 do
			local p = self._players[self._curidx]
			if i == 4 then
				local ok, card = self:take_card()
				assert(ok)
				p:insert(card)
			else
				for i=1,4 do
					local ok, card = self:take_card()
					assert(ok)
					p:insert(card)	
				end
			end
			self._curidx = self:next_idx()
		end
	end

	for i=1,self._max do
		self._players[i]:print_cards()
	end

	-- take first card
	local ok, card = self:take_card()
	assert(ok and self._curidx == self._firstidx)
	self._players[self._curidx]:take_turn_card(card)

	local p1 = self._players[1]:get_cards_value()
	local p2 = self._players[2]:get_cards_value()
	local p3 = self._players[3]:get_cards_value()
	local p4 = self._players[4]:get_cards_value()

	local args = {}
	args.firstidx  = self._firstidx
	args.firsttake = self._firsttake
	args.p1 = p1
	args.p2 = p2
	args.p3 = p3
	args.p4 = p4
	args.card = self._curcard:get_value()

	self:record("deal", args)
	self:push_client("deal", args)
end

function cls:take_xuanque( ... )
	-- body
	self._state = state.TAKE_XUANQUE
	self:clear_state(player.state.WAIT_TAKE_XUANQUE)

	for i=1,self._max do
		self._players[i]:timeout(self._countdown * 100)
	end

	local args = {}
	args.countdown = self._countdown
	args.your_turn = self._curidx
	args.card = 0
	self:record("take_xuanque", args)
	self:push_client("take_xuanque", args)
end

-- 只是拿牌
function cls:take_takecard( ... )
	-- body
	self._laststate = self._state
	self._state = state.TAKECARD
	self:clear_state(player.state.WAIT_TAKECARD)
	local ok, card = self:take_card()
	if not ok then
		self:take_over()
	else
		self._players[self._curidx]:take_turn_card(card)
		local args = {}
		args.idx = self._curidx
		args.card = card:get_value()
		self:push_client("take_card", args)
	end
end

-- 当前用户需要出牌，可能摸了一个牌，也可能是其他
-- 出牌，可能是拿牌，碰，杠
function cls:take_turn( ... )
	-- body
	self._laststate = self._state
	self._state = state.TURN
	self:clear_state(player.state.WAIT_TURN)
	
	local card = self._players[self._curidx]:take_turn_after_peng()
	assert(self._players[self._curidx]._holdcard)
	self._players[self._curidx]:timeout(self._countdown * 100)

	local args = {}
	args.your_turn = self._curidx
	args.countdown = self._countdown

	log.info("player %d take turn, turn type:%d", self._curidx, 0)
	-- self:record("take_turn", args)
	self:push_client("take_turn", args)
end

function cls:take_mcall( ... )
	-- body
	self._call = {}
	self._opinfos = {}
	self._callcounter = 0

	local opcodes = {}

	log.info("take my call player %d check_hu", self._curidx)
	local reshu
	if self._state == state.GANG then
		if self._players[self._curidx]._gang.code == opcode.zhigang then
			reshu = self._players[self._curidx]:check_hu(self._curcard, jiaotype.DIANGANGHUA, self._curidx)
		elseif self._players[self._curidx]._gang.code == opcode.angang then
			reshu = self._players[self._curidx]:check_hu(self._curcard, jiaotype.ZIGANGHUA, self._curidx)
		elseif self._players[self._curidx]._gang.code == opcode.bugang then
			reshu = self._players[self._curidx]:check_hu(self._curcard, jiaotype.ZIGANGHUA, self._curidx)
		else
			assert(false)
		end
	else
		reshu = self._players[self._curidx]:check_hu(self._curcard, jiaotype.ZIMO, self._curidx)
	end

	log.info("take my call player %d check_gang", self._curidx)
	local resgang
	if self._overtype == overtype.XUELIU and self._players[self._curidx]:hashu() then
		resgang = self._players[self._curidx]:check_xueliu_gang(self._curcard, self._curidx)
	else
		resgang = self._players[self._curidx]:check_gang(self._curcard, self._curidx)
	end

	local opinfo = {}
	opinfo.idx = self._curidx
	opinfo.countdown = self._countdown
	opinfo.card = self._curcard:get_value()
	opcode.originalCard = self._curcard
	opinfo.dian = self._curidx
	opinfo.opcode = opcode.none

	local can = false
	if reshu.code ~= opcode.none then
		log.info("take my call player %d call hu code: %d", self._curidx, opinfo.hu.code)

		opinfo.opcode = opinfo.opcode | reshu.code
		opinfo.hutype = reshu.hutype
		opinfo.jiaotype = reshu.jiaotype

		can = true
	end
	if opinfo.gang ~= opcode.none then
		log.info("take my call player %d call gang code: %d", self._curidx, opinfo.gang)

		opinfo.opcode = opinfo.opcode | resgang.code
		opinfo.gangtype = resgang.gangtype
		opinfo.isHoldcard = resgang.isHoldcard


		can = true
	end
	if can then
		self._call[self._curidx] = opinfo
		self._callcounter = 1

		self._laststate = self._state
		self._state = state.MCALL
		self:clear_state(player.state.MCALL)

		self._players[self._curidx]:timeout((self._countdown + 1) * 100)
		table.insert(opcodes, opinfo)

		local args = {}
		args.opcodes = opcodes

		self:record("call", args)
		self:push_client("mcall", args)
		return true
	else
		return false
	end
end

function cls:take_ocall( ... )
	-- body

	self._call = {}
	self._opinfos = {}
	self._callcounter = 0

	local opcodes = {}
	for j=1,self._max do
		local i = self._curidx + j
		if i > self._max then
			i = i - self._max
		end

		if self._curidx == i then
		elseif self._overtype == overtype.XUEZHAN and self._players[i]:hashu() then
		else
			local reshu
			local resgang
			local respeng
			local opinfo = {}
			opinfo.idx = i
			opinfo.countdown = self._countdown
			opinfo.opcode = opcode.none
			if self._state == state.GANG then
				reshu = self._players[i]:check_hu(self._players[self._curidx]._gang.card, jiaotype.QIANGGANGHU, self._curidx)
				if reshu and reshu.code == opcode.hu then
					opinfo.opcode = opinfo | reshu.code
					opinfo.card = reshu.card:get_value()
					opinfo.dian = reshu.dian
					opinfo.hutype = reshu.hutype
					opinfo.jiaotype = reshu.jiaotype
					opinfo.originalCard = reshu.card
				end
			elseif self._state == state.LEAD then
				assert(self._lastcard and self._lastidx)
				opinfo.card = self._lastcard:get_value()
				opinfo.dian = self._lastidx
				opinfo.originalCard = self._lastcard

				log.info("take other call player %d check_hu", i)
				if self._laststate == state.GANG then
					reshu = self._players[i]:check_hu(self._lastcard, jiaotype.GANGSHANGPAO, self._lastidx)
				else
					reshu = self._players[i]:check_hu(self._lastcard, jiaotype.PINGFANG, self._lastidx)
				end
				log.info("take other call player %d check_gang", i)
				if self._overtype == overtype.XUELIU and self._players[i]:hashu() then
					resgang = self._players[i]:check_xueliu_gang(self._lastcard, self._lastidx)
				else
					log.info("take other call player %d check_peng", i)

					resgang = self._players[i]:check_gang(self._lastcard, self._lastidx)
					respeng = self._players[i]:check_peng(self._lastcard, self._lastidx)	
				end

				if reshu and reshu.code == opcode.hu then
					opinfo.opcode = opinfo.opcode | reshu.code
					opinfo.hutype = reshu.hutype
					opinfo.jiaotype = reshu.jiaotype
				end

				if resgang and resgang.code == opcode.gang then
					opinfo.opcode = opinfo.opcode | resgang.code
					opinfo.gangtype = resgang.gangtype
				end

				if respeng and respeng.code == opcode.peng then
					opinfo.opcode = opinfo.opcode | resgang.code
				end
			end

			if opinfo.opcode ~= opcode.none then
				self._call[i] = opinfo
				self._callcounter = self._callcounter + 1
				table.insert(opcodes, opinfo)
				self._players[i]:timeout((self._countdown + 1) * 100)
			end
		end
	end

	if #opcodes > 0 then	
		self._state = state.OCALL
		self:clear_state(player.state.OCALL)

		local args = {}
		args.opcodes = opcodes

		self:record("ocall", args)
		self:push_client("ocall", args)
		return true
	else
		return false
	end
end

function cls:take_over( ... )
	-- body
	self._state = state.OVER
	self:clear_state(player.state.WAIT_OVER)

	-- 检查没有胡玩家的是否有叫，
	-- 1. 没有叫并且刚过，退税
	-- 2. 没有叫给有叫的赔

	local settles = {}
	local wuhu = 0
	for i=1,self._max do
		if not self._players[i]:hashu() then
			wuhu = wuhu + 1
		end
	end
	if wuhu > 1 then
		-- check hua zhu
		local huazhus = {}
		local wudajiaos = {}
		local dajiaos = {}
		for i=1,self._max do
			if self._players[i]:hashu() then
			else
				if self._players[i]:check_que() then
					local res = self._players[i]:check_jiao()
					res.idx = i
					if res.code ~= hutype.NONE then
						table.insert(dajiaos, res)
					else
						table.insert(wudajiaos, res)
					end
				else
					table.insert(huazhus, { idx = i })
				end
			end
		end
		-- tuisui
		if #huazhus > 0 then
			for k,v in pairs(huazhus) do
				local settle = {}
				self._players[v.idx]:tuisui(settle)
				table.insert(settles, settle)
			end
		end

		if #dajiaos == wuhu then
		elseif #dajiaos > 0 then

			for k,v in pairs(dajiaos) do
				local settle = {}

				local base = self._humultiple(v.code, jiaotype.PINGFANG, v.gang)
				local total = 0
				local lose = {}
				local win = {}

				table.insert(win, v.idx)
				for k,h in pairs(wudajiaos) do
					total = total + base
					table.insert(lose, h.idx)

					local litem = {}
					litem.idx  = h.idx
					litem.chip = -base
					litem.left = self._players[litem.idx]:settle(litem.chip)

					litem.win  = win
					litem.lose = lose
					litem.gang = opcode.none
					litem.hucode = v.code
					litem.hujiao = jiaotype.PINGFANG
					litem.hugang = v.gang
					litem.huazhu = 0
					litem.dajiao = 1
					litem.tuisui = 0

					self:insert_settle(settle, litem.idx, litem)
					self._players[litem.idx]:record_settle(litem)
				end
				for k,h in pairs(huazhus) do						
					total = total + base
					table.insert(lose, h.idx)

					local litem = {}
					litem.idx = h.idx
					litem.chip = -base
					litem.left = self._players[litem.idx]:settle(litem.chip)

					litem.win = win
					litem.lose = lose
					litem.gang = opcode.none
					litem.hucode = v.code
					litem.hujiao = hutype.PINGFANG
					litem.hugang = v.gang
					litem.huazhu = 1
					litem.dajiao = 0
					litem.tuisui = 0

					self:insert_settle(settle, litem.idx, litem)
					self._players[h.idx]:record_settle(litem)
				end	

				local witem = {}
				witem.idx = v.idx
				witem.chip = total
				witem.left = self._players[v.idx]:settle(witem.chip)

				witem.win  = win
				witem.lose = lose
				witem.gang = opcode.none
				witem.hucode = v.code
				witem.hujiao = jiaotype.PINGFANG
				witem.hugang = v.gang

				witem.huazhu = 0
				witem.dajiao = 1
				witem.tuisui = 0
				self:insert_settle(settle, witem.idx, witem)
				self._players[v.idx]:record_settle(witem)
			end
		end		
	end

	self:record("over")
	self:push_client("over")
end

function cls:take_settle( ... )
	-- body
	self._state = state.SETTLE
	self:clear_state(player.state.WAIT_SETTLE)

	
	local args = {}
	args.settles = settles

	self:record("settle", args)
	self:push_client("settle", args)
end

function cls:take_final_settle( ... )
	-- body
	self._state = state.FINAL_SETTLE
	self:clear_state(player.state.FINAL_SETTLE)

	local over = false
	if self._ju == self._maxju then
		-- over
		over = true
		skynet.send(".ROOM_MGR", "lua", "enqueue_room", self._id)
		for i=1,self._max do
			local addr = self._players[i]:get_agent()
			skynet.send(addr, "lua", "room_over")
		end
	end

	local args = {}
	args.p1 = self._players[1]._chipli
	args.p2 = self._players[2]._chipli
	args.p3 = self._players[3]._chipli
	args.p4 = self._players[4]._chipli
	args.settles = settles
	args.over = over

	self:record("final_settle", args)
	local recordid = skynet.call(".RECORD_MGR", "lua", "register", cjson.encode(self._record))
	self._record = {}
	local names = {}
	for i=1,self._max do
		table.insert(names, self._players[i]:get_name())
	end
	for i=1,self._max do
		local addr = self._players[i]:get_agent()
		skynet.send(addr, "lua", "record", recordid, names)
	end

	self:push_client("final_settle", args)
end

function cls:take_restart( ... )
	-- body
	self._state = state.RESTART
	self:clear_state(player.state.WAIT_RESTART)

	self:clear()

	for i=1,self._max do
		self._players[i]:take_restart()
	end

	self:push_client("take_restart")
end

function cls:chat(args, ... )
	-- body
	if self._state >= state.READY and self._state < state.OVER then
		self:push_client("rchat", args)
	end
end

function cls:take_roomover( ... )
	-- body
end

function cls:insert_settle(settle, idx, item, ... )
	-- body
	assert(settle and idx and item)
	assert(idx > 0 and idx <= self._max)
	if idx == 1 then
		assert(settle.p1 == nil)
		settle.p1 = item
	elseif idx == 2 then
		assert(settle.p2 == nil)
		settle.p2 = item
	elseif idx == 3 then
		assert(settle.p3 == nil)
		settle.p3 = item
	elseif idx == 4 then
		assert(settle.p4 == nil)
		settle.p4 = item
	else
		assert(false)
	end
end

return cls
