local skynet = require "skynet"
local mc = require "skynet.multicast"
local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local queue = require "chestnut.queue"
local luaTableDump = require "luaTableDump"
local json = require "rapidjson"
local service = require "service"
local savedata = require "savedata"
local traceback = debug.traceback
local assert = assert

-- room
-- room.id          房间id
-- room.addr        房间地址
-- room.mode        房间模式
-- room.rule        房间规则
-- room.joined      房间加入的人数
-- room.users       房间已经加入的人员
-- room.users ==> user = { uid, agent }

local ROOM_NAME = skynet.getenv 'room_name'
local users = {}   -- 玩家信息,玩家创建的房间
local rooms = {}   -- 私人打牌的
local num = 0      -- 正在打牌的桌子数
local mrooms = {}  -- 所有匹配的房间
local q = queue()  -- 排队的队列
local pool = {}    -- 闲置的桌子
local startid = 101010 -- 101010
local id = startid
local MAX_ROOM_NUM = 10
local constscfg
local roommodecfg


skynet.init(function ( ... )
	-- body
	constscfg = ds.query('constsConfig')
	roommodecfg = ds.query('roommodeConfig')
end)

-- @breif 生成自创建房间id，
-- @return 0,成功, 13 超过最大房间数
local function next_id()
	-- body
	if num >= MAX_ROOM_NUM then
		return 13
	else
		while rooms[id] do
			id = id + 1
			if id >= startid + MAX_ROOM_NUM then
				id = startid
			end
		end
		return 0, id
	end
end

local CMD = {}
local SUB = {}

function SUB.save_data( ... )
	-- body
	CMD.save_data()
end

function CMD.start(channel_id)
	-- body
	savedata.init {
		channel_id = channel_id,
		command = SUB
	}

	-- 初始一些配置
	startid = 101010 -- 101010
	MAX_ROOM_NUM = tonumber(constscfg['2']['Value'])
	assert(MAX_ROOM_NUM > 1)
	log.info('MAX_ROOM_NUM ==> %d', MAX_ROOM_NUM)

	-- 初始所有桌子
	for i=1,MAX_ROOM_NUM do
		local roomid = startid + i - 1
		local addr = skynet.newservice(ROOM_NAME, roomid)
		skynet.call(addr, "lua", "start", channel_id)
		pool[roomid] = { type=0, mode=1, id = roomid, addr = addr, joined=0, users={} }
	end

	return true
end

function CMD.init_data()
	-- body
	-- 初始自定义房间数据
	-- local pack = skynet.call('.DB', "lua", "read_room_mgr")
	-- skynet.error(luaTableDump(pack))
	-- if pack then
	-- 	for _,db_user in pairs(pack.db_users) do
	-- 		if db_user.roomid ~= 0 then
	-- 			local user = {}
	-- 			user.uid    = assert(db_user.uid)
	-- 			user.roomid = assert(db_user.roomid)
	-- 			users[tonumber(user.uid)] = user
	-- 		end
	-- 	end
	-- 	-- 初始化rooms
	-- 	for _,db_room in pairs(pack.db_rooms) do
	-- 		if db_room.host ~= 0 then
	-- 			local room = {}
	-- 			room.id   = assert(db_room.id)
	-- 			room.type = assert(db_room.type)
	-- 			room.mode = assert(db_room.mode)
	-- 			room.host = assert(db_room.host)
	-- 			room.ju   = assert(db_room.ju)
	-- 			room.users = {}
	-- 			local xusers = json.decode(db_room.users)
	-- 			for _,v in pairs(xusers) do
	-- 				local user = {}
	-- 				user.uid = assert(v.uid)
	-- 				user.idx = assert(v.idx)
	-- 				user.chip = assert(v.chip)
	-- 				room.users[tointeger(v.uid)] = user
	-- 			end
	-- 			rooms[tonumber(room.id)] = room
	-- 		end
	-- 	end
	-- end

	return true

	-- -- 验证每个房间是否还有存在的可能你
	-- for k,v in pairs(rooms) do
	-- 	if v.ju < 1 then
	-- 		local room = assert(pool[k])
	-- 		v.addr = room.addr
	-- 		pool[k] = nil
	-- 		num = num + 1
	-- 		if k > id then
	-- 			id = k
	-- 		end
	-- 	else
	-- 		-- 此房间应该解散，修改离线用户数据
	-- 		users[v.host] = nil
	-- 		for i,uid in ipairs(v.users) do
	-- 			skynet.call('.OFFAGENT_MGR', "lua", "write_offuser_room", uid)
	-- 		end
	-- 		rooms[k] = nil
	-- 	end
	-- end

	-- -- 初始所有自创建房间数据
	-- for _,v in pairs(rooms) do
	-- 	local ok = skynet.call(v.addr, "lua", "init_data")
	-- 	assert(ok)
	-- end
	-- return true
end

function CMD.sayhi()
	-- body
	-- 创建类房间sayhi恢复一些操作
	for _,v in pairs(rooms) do
		local ok = skynet.call(v.addr, "lua", "sayhi", v.type, v.mode, v.host)
		assert(ok)
	end

	-- 创建匹配房间
	-- 匹配类房间在sayhi的时候就必须准备好
	-- 而创建房间需要房主，所以需要等到create的时候才真的创建
	for _,v in pairs(pool) do
		assert(v.addr)
		skynet.call(v.addr, "lua", "sayhi", v.type, v.mode, v.host, v.users)
	end
	return true
end

function CMD.save_data()
	-- body
	-- 清除已经解散的数据
	for k,v in pairs(users) do
		if v.roomid == 0 then
			users[k] = nil
		end
	end
	for k,v in pairs(rooms) do
		if v.host == 0 then
			pool[k] = v
			rooms[k] = nil
		end
	end
	-- 存创建房间的用户与房间数据
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
		db_room.type = assert(v.type)
		db_room.mode = assert(v.mode)
		if v.users == nil then
			log.error(v.id)
		end
		local xusers = {}
		for k,v in pairs(v.users) do
			local user = {}
			user.uid = assert(v.uid)
			user.idx = assert(v.idx)
			user.chip = assert(v.chip)
			xusers[tostring(k)] = user
		end
		db_room.users = json.encode(xusers)
		db_room.ju = v.ju
		db_rooms[string.format("%d", k)] = db_room
	end
	local data = {}
	data.db_users = db_users
	data.db_rooms = db_rooms
	skynet.call(".DB", "lua", "write_room_mgr", data)
	return NORET
end

function CMD.close()
	-- body
	-- 回收匹配房间
	for _,room in pairs(mrooms) do
		skynet.call(room.addr, 'lua', 'recycle')
	end
	-- 存储数据
	CMD.save_data()
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

------------------------------------------
-- 匹赔
function CMD.match(uid, agent, mode)
	-- body
	print(mode)
	local res = {}
	res.errorcode = 0
	local roommode = ds.query('roommode')
	local xmode = assert(roommode['1'])
	
	local user = {
		uid = uid,
		agent = agent,
		mode = mode
	}
	q:enqueue(user)
	-- 标记已经开始匹配了
	skynet.retpack(res)

	-- 匹配成功
	if #q >= xmode.join then
		local res = {}
		local errorcode, roomid = next_id()
		if errorcode ~= 0 then
			-- 没有足够的房间了
			local args = { errorcode=-1, roomid=roomid }
			skynet.send(agent, 'lua', 'pokermatch', args)	
		else
			local args = { errorcode=0, roomid=roomid }
			skynet.send(agent, 'lua', 'pokermatch', args)
		end
	end
	return NORET
end

------------------------------------------
-- 创建房间
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
		assert(roomid >= startid and roomid < startid + MAX_ROOM_NUM)
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
			room.type = 1
			room.mode = 1
			room.rule = args
			room.host = uid
			room.ju = 0
			room.users = {}
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
	assert(roomid)
	log.info("apply roomid: %d, return room addr", roomid)
	-- 判断创建类房间是否存在
	local room = rooms[roomid]
	if room then
		assert(room.addr)
		return { errorcode = 0, addr = room.addr }
	else
		room = mrooms[roomid]
		if room then
			return { errorcode = 0, addr = room.addr }
		else
			return { errorcode = 14 }
		end
	end
end

-- 解散房间 call by room
function CMD.dissolve(roomid)
	-- body
	local room = assert(rooms[roomid])
	skynet.call(room.addr, 'lua', 'recycle')
	local user = users[room.host]
	user.roomid = 0
	room.host = 0
	room[roomid] = nil
	pool[room.id] = room
	return NORET
end

------------------------------------------
-- called by room
function CMD.room_join(roomid, uid, agent, idx, chip)
	-- body
	assert(roomid and uid and agent and idx and chip)
	local room = rooms[roomid]
	if room then
		room.users[uid] = { uid=uid, agent=agent, idx=idx, chip=chip }
		room.joined = room.joined + 1
	else
		room = mrooms[roomid]
		if room then
			room.users[uid] = { uid=uid, agent=agent, idx=idx, chip=chip }
			room.joined = room.joined + 1
		end
	end
	return true
end

function CMD.room_rejoin(roomid, uid, agent)
	-- body
	assert(roomid and uid and agent)
	local room = assert(rooms[roomid])
	if room then
		local user = assert(room.users[uid])
		user.agent = agent
	else
		room = mrooms[roomid]
		if room then
			local user = assert(room.users[uid])
			user.agent = agent
		else
			assert(false)
		end
	end
	return true
end

function CMD.room_afk(roomid, uid)
	-- body
	assert(roomid and uid)
	local room = rooms[roomid]
	if room then
		local user = assert(room.users[uid])
		user.agent = nil
	else
		room = mrooms[roomid]
		if room then
			local user = assert(room.users[uid])
			user.agent = nil
		end
	end
	return true
end

function CMD.room_leave(roomid, uid)
	-- body
	assert(roomid and uid)
	local room = rooms[roomid]
	if room then
		assert(room.joined > 0)
		room.joined = room.joined - 1
		room.users[uid] = nil
	else
		room = mrooms[roomid]
		if room then
			assert(room.joined > 0)
			room.joined = room.joined - 1
			assert(room.users[uid])
			room.users[uid] = nil
		end
	end
	return true
end

------------------------------------------
-- 房间
function CMD.room_check_nextju(roomid)
	-- body
	assert(roomid)
	local room = assert(rooms[roomid])
	if room.ju >= 1 then
		return false
	end
	return true
end

function CMD.room_incre_ju(roomid)
	-- body
	assert(roomid)
	local room = assert(rooms[roomid])
	if room.ju >= 1 then
		return false
	end
	room.ju = room.ju + 1
	return true
end

function CMD.room_is_1stju(roomid)
	-- body
	assert(roomid)
	local room = assert(rooms[roomid])
	if room.ju == 0 then
		return true
	end
	return false
end

service.init {
	name = '.ROOM_MGR',
	command = CMD
}
