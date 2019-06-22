local skynet = require "skynet"
local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local client = require "client"

local cls = {}

------------------------------------------
-- event
function cls:on_data_init(dbData)
	-- body
	assert(dbData)
	assert(dbData.db_user_rooms ~= nil and #dbData.db_user_rooms >= 0)
	self.dbRoom = {}
	if #dbData.db_user_rooms == 1 then
		local seg = dbData.db_user_rooms[1]
		self.dbRoom.id        = assert(seg.roomid)
		self.dbRoom.isCreated = (assert(seg.created) == 1) and true or false
		self.dbRoom.joined    = (assert(seg.joined) == 1) and true or false
		self.dbRoom.type      = assert(seg.type)
		self.dbRoom.mode      = assert(seg.mode)
		self.dbRoom.createAt  = assert(seg.create_at)
		self.dbRoom.updateAt  = assert(seg.update_at)
	else
		self.dbRoom.id        = 0
		self.dbRoom.isCreated = false
		self.dbRoom.joined    = false
		self.dbRoom.type      = 0
		self.dbRoom.mode      = 0
		self.dbRoom.createAt  = os.time()
		self.dbRoom.updateAt  = os.time()
	end
end

function cls:on_data_save(dbData, ... )
	-- body
	assert(dbData ~= nil)
	dbData.db_user_room = {}
	dbData.db_user_room.uid = self.agentContext.uid
	dbData.db_user_room.roomid  = self.dbRoom.id
	dbData.db_user_room.type    = self.dbRoom.type
	dbData.db_user_room.mode    = self.dbRoom.mode
	dbData.db_user_room.created = self.dbRoom.isCreated and 1 or 0
	dbData.db_user_room.joined = self.dbRoom.joined and 1 or 0
	dbData.db_user_room.create_at = self.dbRoom.createAt
	dbData.db_user_room.update_at = os.time()
end

function cls:on_enter( ... )
	-- body
	local D = self.dbRoom
	if D.joined then
		local res = skynet.call(".ROOM_MGR", "lua", "apply", D.db.id)
		if res.errorcode ~= 0 then
			log.error('room mgr')
		else
			D.addr = res.addr
			local ok = skynet.call(D.addr, "lua", "auth", self.uid)
			if not ok then
				log.error("auth not ")
			end
		end
	end

	local res = {}
	res.errorcode = 0
	res.isCreated = D.db.isCreated
	res.joined    = D.db.joined
	res.roomid    = D.db.id
	res.type      = D.db.type
	res.mode      = D.db.mode
	client.push(self, 'room_info', res)
end

function cls:on_exit( ... )
	-- body
	local D = self.room
	if D.joined and D.online then
		local ok = skynet.call(D.addr, "lua", "on_afk", obj.uid)
		assert(ok)
		D.online = false
		D.addr = 0
	end
end

function cls:on_func_open()
	-- body
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	entity.room.isCreated = false
	entity.room.joined = false
	entity.room.id = 0
	entity.room.addr = 0
	entity.room.type = 0                     -- 这个字段没有用
	entity.room.mode = 0                     -- 这个字段没有用
	entity.room.createAt = os.time()
	entity.room.updateAt = os.time()
end

-- event
------------------------------------------



function cls:match(args)
	-- body
	
	local res = {}
	-- 匹配
	if self.dbRoom.matching then
		res.errorcode = 18
		return res
	end
	if self.dbRoom.joined then
		res.errorcode = 15
		return res
	end
	local agent = skynet.self()
	res = skynet.call(".ROOM_MGR", "lua", "match", uid, agent, args.mode)
	log.info('match %d', args.mode)
	if res.errorcode == 0 then
		self.dbRoom.matching = false
	end
	return res
end

function cls:create(args)
	-- body
	if self.dbRoom.isCreated then
		local res = {}
		res.errorcode = 10
		return res
	end

	if self.dbRoom.joined then
		local res = {}
		res.errorcode = 11
		return res
	end

	local agent = skynet.self()
	local res = skynet.call(".ROOM_MGR", "lua", "create", uid, agent, args)
	if res.errorcode == 0 then
		room.id        = res.roomid
		room.isCreated = true
	end
	return res
end

function cls:join(args)
	-- body
	if self.dbRoom.isCreated then
		if self.dbRoom.id ~= args.roomid then
			return { errorcode = 1 }
		end
	end

	local user = self.systems.user
	local xargs = {
		uid   = uid,
		agent = agent,
		name  = assert(user.nickname),
		sex   = assert(user.sex)
	}
	local res = skynet.call(".ROOM_MGR", "lua", "apply", args.roomid)
	if res.errorcode ~= 0 then
		return res
	else
		local response = skynet.call(res.addr, "lua", "on_join", xargs)
		if response.errorcode == 0 then
			log.info("join room SUCCESS.")
			self.dbRoom.id = args.roomid
			self.dbRoom.addr = res.addr
			self.dbRoom.joined = true
			self.dbRoom.online = true
			self.dbRoom.mode = assert(response.mode)
			self.dbRoom.type = assert(response.type)
		else
			log.info('join room FAIL.')
		end
		return response
	end
end

function cls:rejoin()
	-- body
	local uid   = self.agentContext.uid
	local agent = skynet.self()
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	if not entity.room.joined then
		return { errorcode = 1 }
	end

	local xargs = {
		uid   = uid,
		agent = agent,
		name  = assert(entity.user.nickname),
		sex   = assert(entity.user.sex)
	}
	local res = skynet.call(".ROOM_MGR", "lua", "apply", entity.room.id)
	if res.errorcode ~= 0 then
		return res
	else
		local response = skynet.call(res.addr, "lua", "on_rejoin", xargs)
		if response.errorcode == 0 then
			entity.room.addr   = res.addr
			entity.room.joined = true
			entity.room.online = true
		else
			log.info('join room FAIL.')
		end
		return response
	end
end

-- called by client
function cls:leave()
	-- body
	log.info('RoomSystem leave')
	local uid   = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	if entity.room.joined then
		local res = skynet.call(entity.room.addr, 'lua', 'on_leave', uid)
		log.info('call room leave')
		if res.errorcode == 0 then
			entity.room.isCreated = false
			entity.room.joined = false
			entity.room.id = 0
			entity.room.mode = 0
		else
			log.error('uid(%d) leave failture.', uid)
		end
	end
	return true
end

-- called by room
function cls:roomover()
	-- body
	self.dbRoom.id = 0
	self.dbRoom.joined = false
	self.dbRoom.isCreated = false
	return true
end

function cls:forward_room(name, args)
	-- body
	if self.dbRoom.joined then
		local cmd = "on_"..name
		local addr = self.addr
		log.info("route request command %s agent to room", cmd)
		return skynet.call(addr, "lua", cmd, args)
	else
		local res = {}
		res.errorcode = 15
		return res
	end
end

function cls:forward_room_rsp(name, args)
	-- body
	if self.dbRoom.joined then
		local cmd = name
		local addr = self.addr
		log.info("route response command %s agent to room", cmd)
		skynet.send(addr, "lua", cmd, args)
	end
end

return cls