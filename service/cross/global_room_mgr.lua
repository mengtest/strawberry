package.path = "./module/dezhou/lualib/?.lua;"..package.path
local skynet = require "skynet"
require "skynet.manager"
local mc = require "skynet.multicast"
local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local redis = require "chestnut.redis"
local json = require "rapidjson"

local channel_id
local NORET = {}
local users = {}   -- 玩家信息
local rooms = {}   -- 正在打牌的
local num = 0      -- 正在打牌的桌子数
local pool = {}    -- 闲置的桌子
local bank = 101010
local MAX_ROOM_NUM = 4
local id = bank + 1

-- @breif 生成房间id，
-- @return 0,成功, 13 超过最大房间数
local function next_id()
	-- body
	if num >= MAX_ROOM_NUM then
		return 13
	else
		while rooms[id] do
			id = id + 1
			if id > bank + MAX_ROOM_NUM then
				id = bank + 1
			end
		end
		return 0, id
	end
end


local CMD = {}

function CMD.start(chan_id)
	-- body
	local channel = mc.new {
		channel = chan_id,
		dispatch = function (_, _, cmd, ...)
			-- body
			local f = assert(CMD[cmd])
			local r = f( ... )
			if r ~= NORET then
				if r ~= nil then
					skynet.retpack(r)
				else
					log.error("subscribe cmd = %s not return", cmd)
				end
			end
		end
	}
	channel:subscribe()
	channel_id = chan_id

	-- 初始一些配置
	MAX_ROOM_NUM = tonumber(ds.query('consts')['2']['Value'])
	assert(MAX_ROOM_NUM > 1)
	log.info('MAX_ROOM_NUM ==> %d', MAX_ROOM_NUM)

	-- 初始所有桌子
	for i=1,MAX_ROOM_NUM do
		local roomid = bank + i
		local addr = skynet.newservice("room/room", roomid)
		pool[roomid] = { id = roomid, addr = addr }
	end
	return true
end

function CMD.init_data()
	-- body
	local pack = redis:get("tb_room_mgr")
	if pack then
		log.info("pack = [%s]", pack)
		local data = json.decode(pack)
		for k,v in pairs(data.users) do
			local db_user = {}
			db_user.uid = assert(v.uid)
			db_user.roomid = assert(v.roomid)
			users[tonumber(k)] = db_user
		end
		for k,v in pairs(data.rooms) do
			local db_room = {}
			db_room.id = assert(v.id)
			db_room.host = assert(v.host)
			rooms[tonumber(k)] = db_room
		end
	end
	-- 打开所有房间
	for _,room in pairs(pool) do
		local ok = skynet.call(room.addr, "lua", "start", channel_id)
		if not ok then
			log.error("start room id = %d failed.", room.id)
		else
			ok = skynet.call(room.addr, "lua", "init_data")
			assert(ok)
		end
	end

	-- 验证mgr数据与room数据的一致
	for k,v in pairs(rooms) do
		local room = pool[k]
		local ok = skynet.call(room.addr, "lua", "sayhi")
		if ok then
			v.addr = room.addr
			pool[k] = nil
			num = num + 1
			if k > id then
				id = k
			end
		else
			log.error("room data wrong.")
		end
	end
	return true
end

function CMD.sayhi()
	-- body
	return true
end

function CMD.save_data()
	-- body
	local db_users = {}
	local db_rooms = {}
	for k,v in pairs(users) do
		local db_user = {}
		db_user.uid = assert(v.uid)
		db_user.roomid = assert(v.roomid)
		db_users[string.format("%d", k)] = db_user
	end
	for k,v in pairs(rooms) do
		local db_room = {}
		db_room.id = assert(v.id)
		db_room.host = assert(v.host)
		db_rooms[string.format("%d", k)] = db_room
	end
	local data = {}
	data.users = db_users
	data.rooms = db_rooms
	local pack = json.encode(data)
	redis:set("tb_room_mgr", pack)
	return NORET
end

function CMD.close()
	-- body
	CMD.save_data()
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

------------------------------------------
-- match
function CMD.enqueue_agent(source, uid, rule, mode, scene, ... )
	-- body
	log.info("enqueue_agent")
	local rt = ((scene & 0xff << 16) | (mode & 0xff << 8) | (rule & 0xff))
	local agent = {
		agent = source,
		uid = uid,
		sid = sid,
		rt = rt,
		rule = rule,
		mode = mode,
		scene = scene,
	}
	users[uid] = agent
	mgr:enqueue_agent(rt, agent)

	if mgr:get_agent_queue_sz(rt) >= 3 then
		log.info("room number more than 3")
		local room = mgr:dequeue_room()
		for i=1,3 do
			local u = mgr:dequeue_agent(rt)
			skynet.send(u.agent, "lua", "enter_room", room.id)
			users[u.uid] = nil
		end	
	end
	return noret
end

function CMD.dequeue_agent(source, uid, ... )
	-- body
	assert(uid)
	local u = users[uid]
	if u then
		mgr:remove_agent(u)
		users[uid] = nil
	end
end

-- open room------------------------------------------------------
function CMD.create(uid, agent, args)
	-- body
	log.info("ROOM_MGR create")
	local u = users[uid]
	if u then
		local res = {}
		res.errorcode = 10
		return res
	else
		local res = {}
		local errorcode, roomid = next_id()
		if errorcode ~= 0 then
			res.errorcode = errorcode
			return res
		end
		assert(roomid >= bank + 1 and roomid <= bank + MAX_ROOM_NUM)
		local room = assert(pool[roomid])

		res = skynet.call(room.addr, "lua", "create", uid, args)
		if res.errorcode ~= 0 then
			return res
		else
			u = {}
			u.uid = uid
			u.roomid = room.id
			u.agent = agent
			users[uid] = u

			-- room
			pool[roomid] = nil
			room.rule = args
			room.host = uid
			rooms[roomid] = room
			num = num + 1

			log.info("create room ok")
			return res
		end
	end
end

-- 查询房间地址
function CMD.apply(roomid)
	-- body
	log.info("apply roomid: %d, return room addr", roomid)
	local room = rooms[roomid]
	if room then
		return { errorcode = 0, addr = room.addr }
	else
		return { errorcode = 14 }
	end
end

-- 解散房间 call by room
function CMD.dissolve(roomid)
	-- body
	local room = rooms[roomid]
	assert(room)
	rooms[roomid] = nil
	assert(pool[roomid] == nil)
	pool[roomid] = room
	return true
end


skynet.start(function ()
	-- body
	skynet.dispatch("lua", function ( _, _, cmd, ... )
		-- body
		local f = assert(CMD[cmd])
		local r = f( ... )
		if r ~= NORET then
			if r ~= nil then
				skynet.retpack(r)
			else
				log.error("ROOM_MGR cmd = %d  not return", cmd)
			end
		end
	end)
	skynet.register ".ROOM_MGR"
end)