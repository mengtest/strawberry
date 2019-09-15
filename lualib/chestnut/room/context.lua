local skynet = require "skynet"
local sd = require "skynet.sharetable"
local log = require "chestnut.skynet.log"
local client = require "client"

local _M = {}

------------------------------------------
-- event
function _M:on_data_init(dbData)
	-- body
	assert(dbData)
	assert(dbData.db_user_rooms ~= nil and #dbData.db_user_rooms >= 0)
	self.mod_room = {}
	if #dbData.db_user_rooms == 1 then
		local seg = dbData.db_user_rooms[1]
		self.mod_room.id = assert(seg.roomid)
		self.mod_room.isCreated = (assert(seg.created) == 1) and true or false
		self.mod_room.joined = (assert(seg.joined) == 1) and true or false
		self.mod_room.type = assert(seg.type)
		self.mod_room.mode = assert(seg.mode)
		self.mod_room.createAt = assert(seg.create_at)
		self.mod_room.updateAt = assert(seg.update_at)
	else
		self.mod_room.id = 0
		self.mod_room.isCreated = false
		self.mod_room.joined = false
		self.mod_room.type = 0
		self.mod_room.mode = 0
		self.mod_room.createAt = os.time()
		self.mod_room.updateAt = os.time()
	end
end

function _M:on_data_save(dbData)
	-- body
	assert(dbData ~= nil)
	dbData.db_user_room = {}
	dbData.db_user_room.uid = self.uid
	dbData.db_user_room.roomid = self.mod_room.id
	dbData.db_user_room.type = self.mod_room.type
	dbData.db_user_room.mode = self.mod_room.mode
	dbData.db_user_room.created = self.mod_room.isCreated and 1 or 0
	dbData.db_user_room.joined = self.mod_room.joined and 1 or 0
	dbData.db_user_room.create_at = self.mod_room.createAt
	dbData.db_user_room.update_at = os.time()
end

function _M:on_enter()
	-- body
	local D = self.mod_room
	if D.joined then
		local res = skynet.call(".ROOM_MGR", "lua", "apply", D.db.id)
		if res.errorcode ~= 0 then
			log.error("room mgr")
		else
			D.addr = res.addr
			local ok = skynet.call(D.addr, "lua", "auth", self.uid)
			if not ok then
				log.error("auth not ")
			end
		end
	end

	local req = {}
	req.isCreated = false
	req.joined = false
	req.roomid = D.id
	req.type = D.type
	req.mode = D.mode
	client.push(self, "room_info", req)
end

function _M:on_exit(...)
	-- body
	local D = self.room
	if D.joined and D.online then
		local ok = skynet.call(D.addr, "lua", "on_afk", obj.uid)
		assert(ok)
		D.online = false
		D.addr = 0
	end
end

function _M:on_func_open()
	-- body
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	entity.room.isCreated = false
	entity.room.joined = false
	entity.room.id = 0
	entity.room.addr = 0
	entity.room.type = 0 -- 这个字段没有用
	entity.room.mode = 0 -- 这个字段没有用
	entity.room.createAt = os.time()
	entity.room.updateAt = os.time()
end

-- event
------------------------------------------
function _M:match(args)
	-- body

	local res = {}
	-- 匹配
	if self.mod_room.matching then
		res.errorcode = 18
		return res
	end
	if self.mod_room.joined then
		res.errorcode = 15
		return res
	end
	local agent = skynet.self()
	res = skynet.call(".ROOM_MGR", "lua", "match", uid, agent, args.mode)
	log.info("match %d", args.mode)
	if res.errorcode == 0 then
		self.mod_room.matching = false
	end
	return res
end

function _M:create(args)
	-- body
	if self.mod_room.isCreated then
		local res = {}
		res.errorcode = 10
		return res
	end

	if self.mod_room.joined then
		local res = {}
		res.errorcode = 11
		return res
	end

	local agent = skynet.self()
	local res = skynet.call(".ROOM_MGR", "lua", "create", uid, agent, args)
	if res.errorcode == 0 then
		room.id = res.roomid
		room.isCreated = true
	end
	return res
end

function _M:join(args)
	-- body
	if self.mod_room.isCreated then
		if self.mod_room.id ~= args.roomid then
			return {errorcode = 1}
		end
	end

	local user = self.systems.user
	local xargs = {
		uid = uid,
		agent = agent,
		name = assert(user.nickname),
		sex = assert(user.sex)
	}
	local res = skynet.call(".ROOM_MGR", "lua", "apply", args.roomid)
	if res.errorcode ~= 0 then
		return res
	else
		local response = skynet.call(res.addr, "lua", "on_join", xargs)
		if response.errorcode == 0 then
			log.info("join room SUCCESS.")
			self.mod_room.id = args.roomid
			self.mod_room.addr = res.addr
			self.mod_room.joined = true
			self.mod_room.online = true
			self.mod_room.mode = assert(response.mode)
			self.mod_room.type = assert(response.type)
		else
			log.info("join room FAIL.")
		end
		return response
	end
end

function _M:rejoin()
	-- body
	local uid = self.agentContext.uid
	local agent = skynet.self()
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	if not entity.room.joined then
		return {errorcode = 1}
	end

	local xargs = {
		uid = uid,
		agent = agent,
		name = assert(entity.user.nickname),
		sex = assert(entity.user.sex)
	}
	local res = skynet.call(".ROOM_MGR", "lua", "apply", entity.room.id)
	if res.errorcode ~= 0 then
		return res
	else
		local response = skynet.call(res.addr, "lua", "on_rejoin", xargs)
		if response.errorcode == 0 then
			entity.room.addr = res.addr
			entity.room.joined = true
			entity.room.online = true
		else
			log.info("join room FAIL.")
		end
		return response
	end
end

-- called by client
function _M:leave()
	-- body
	log.info("RoomSystem leave")
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	if entity.room.joined then
		local res = skynet.call(entity.room.addr, "lua", "on_leave", uid)
		log.info("call room leave")
		if res.errorcode == 0 then
			entity.room.isCreated = false
			entity.room.joined = false
			entity.room.id = 0
			entity.room.mode = 0
		else
			log.error("uid(%d) leave failture.", uid)
		end
	end
	return true
end

-- called by room
function _M:roomover()
	-- body
	self.mod_room.id = 0
	self.mod_room.joined = false
	self.mod_room.isCreated = false
	return true
end

function _M:forward_room(name, args)
	-- body
	if self.mod_room.joined then
		local cmd = "on_" .. name
		local addr = self.addr
		log.info("route request command %s agent to room", cmd)
		return skynet.call(addr, "lua", cmd, args)
	else
		local res = {}
		res.errorcode = 15
		return res
	end
end

function _M:forward_room_rsp(name, args)
	-- body
	if self.mod_room.joined then
		local cmd = name
		local addr = self.addr
		log.info("route response command %s agent to room", cmd)
		skynet.send(addr, "lua", cmd, args)
	end
end

return _M
