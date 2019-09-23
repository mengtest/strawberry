local skynet = require "skynet"
local service = require "service"
local log = require "chestnut.skynet.log"
local context = require "chestnut.chat_mgr.context"
local traceback = debug.traceback
local assert = assert
local CMD = {}

function CMD.start()
	context.init()
	return true
end

function CMD.init_data()
	-- context.on_data_init()
	return true
end

function CMD.sayhi()
	return true
end

function CMD.close()
	return true
end

function CMD.kill()
	skynet.exit()
end

------------------------------------------
-- 签到
function CMD.login(uid, agent)
	local u = {
		uid = uid,
		agent = agent
	}
	context.login(u)
end

function CMD.afk(uid)
	context.afk(uid)
end

------------------------------------------
-- 房间信息
function CMD.room_create(room_id, addr)
	-- body
	assert(room_id and addr)
	assert(rooms[room_id] == nil)
	rooms[room_id] = {}
	rooms[room_id].addr = addr
	rooms[room_id].users = {}
	return true
end

function CMD.room_init_users(room_id, xusers)
	-- body
	local room = rooms[room_id]
	for k, v in pairs(xusers) do
		room.users[k] = {uid = v.uid}
	end
	return true
end

function CMD.room_join(room_id, uid, agent)
	-- body
	local room = rooms[room_id]
	room.users[uid] = {uid = uid, agent = agent}
	return true
end

function CMD.room_rejoin(room_id, uid, agent)
	-- body
	assert(room_id and uid and agent)
	local room = assert(rooms[room_id])
	local user = assert(room.users[uid])
	user.agent = agent
	return true
end

function CMD.room_afk(room_id, uid)
	-- body
	assert(room_id and uid)
	local room = assert(rooms[room_id])
	local user = assert(room.users[uid])
	user.agent = nil
	return true
end

function CMD.room_leave(room_id, uid)
	-- body
	assert(room_id and uid)
	local room = rooms[room_id]
	if room then
		room.users[uid] = nil
	else
		log.error("room(%d) leave", room_id)
	end
	return true
end

function CMD.room_recycle(room_id)
	-- body
	rooms[room_id] = nil
	return true
end

function CMD.say(from, to, word)
end

return CMD
