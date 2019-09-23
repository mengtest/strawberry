local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local db_read = require "db.db_read"
local db_write = require "db.db_write"
local util = require "db.util"
local address
local ctx
local QUERY = {}

local function get_address()
	if not address then
		address = skynet.uniqueservice "db"
	end
	return address
end

function QUERY.start(...)
	-- body
	local db = util.connect_mysql()
	ctx = {db = db, dump = util.dump}
end

function QUERY.close()
	-- body
	util.disconnect_mysql(db)
end

function QUERY.kill()
	-- body
	skynet.exit()
end

------------------------------------------
-- read data

function QUERY.read_account_by_username(username, password)
	-- body
	local res = {}
	local accounts = db_read.read_account_by_username(ctx, username, password)
	if #accounts == 1 then
		local users = db_read.read_users_by_uid(ctx, accounts[1].uid)
		res.accounts = accounts
		res.users = users
	end
	return res
end

function QUERY.read_auth_by_openid(openid)
end

function QUERY.read_user(uid)
	local res = {}
	res.db_users = db_read.read_users_by_uid(ctx, uid)
	res.db_user_rooms = db_read.read_user_rooms(ctx, uid)
	res.db_user_items = db_read.read_user_packages(ctx, uid)
	res.db_user_funcopens = db_read.read_user_funcopens(ctx, uid)
	res.db_user_heros = db_read.read_user_heros(ctx, uid)
	res.db_user_friends = db_read.read_user_friends(ctx, uid)
	res.db_user_friend_reqs = db_read.read_user_friend_reqs(ctx, uid)
	return res
end

function QUERY.read_sysmail()
	local res = {}
	res.db_sysmails = db_read.read_sysmail(ctx)
	return res
end

function QUERY.read_room_mgr()
	local res = {}
	res.db_users = db_read.read_room_mgr_users(ctx)
	res.db_rooms = db_read.read_room_mgr_rooms(ctx)
	return res
end

function QUERY.read_room(id)
	local res = {}
	res.db_rooms = db_read.read_room(ctx, id)
	res.db_users = db_read.read_room_users(ctx, id)
	return res
end

function QUERY.read_zset(tname)
	local res = {}
	res.db_zset = db_read.read_zset(ctx, tname)
	return res
end

------------------------------------------
-- 写数据
function QUERY.write_account(db_account)
	db_write.write_account(ctx, db_account)
end

function QUERY.write_auth(data)
end

function QUERY.write_union(db_union)
end

function QUERY.write_user(data)
	db_write.write_user(ctx, data.db_user)
	db_write.write_user_room(ctx, data.db_user_room)
	db_write.write_user_package(ctx, data.db_user_items)
	db_write.write_user_funcopen(ctx, data.db_user_funcopens)
	db_write.write_user_achievement(ctx, data.db_user_achievements)
	db_write.write_user_heros(ctx, data.db_user_heros)
	db_write.write_user_friends(ctx, data.db_user_friends)
end

function QUERY.write_sysmail()
end

function QUERY.write_room_mgr(data)
	-- body
	db_write.write_room_mgr_users(ctx, data.db_users)
	db_write.write_room_mgr_rooms(ctx, data.db_rooms)
end

function QUERY.write_room(data)
	-- body
	db_write.write_room_users(ctx, data.db_users)
	db_write.write_room(ctx, data.db_room)
end

function QUERY.write_zset(tname, data)
	db_write.write_zset(ctx, tname, data)
end

------------------------------------------
-- 修改离线数据
function QUERY.write_offuser_room(db_user_room)
	-- body
	db_write.write_offuser_room_created(ctx, db_user_room)
end

-------------------------------------------------------------end

local _M = {}

_M.host = QUERY

function _M.read_sysmail(...)
	-- body
	local handle = get_address()
	return skynet.call(handle, "lua", "read_sysmail")
end

function _M.read_account_by_username(username, password)
	local handle = get_address()
	return skynet.call(handle, "lua", "read_account_by_username", username, password)
end

function _M.read_user(uid)
	local handle = get_address()
	return skynet.call(handle, "lua", "read_user", uid)
end

function _M.read_room_mgr()
	local handle = get_address()
	return skynet.call(handle, "lua", "read_room_mgr")
end

function _M.read_room(roomid)
	local handle = get_address()
	return skynet.call(handle, "lua", "read_room", roomid)
end

function _M.read_zset(tname)
	local handle = get_address()
	return skynet.call(handle, "lua", "read_zset", tname)
end

function _M.write_account(account)
	local handle = get_address()
	skynet.send(handle, "lua", "write_account", account)
end

function _M.write_union(union)
	local handle = get_address()
	skynet.send(handle, "lua", "write_union", union)
end

function _M.write_user(user)
	local handle = get_address()
	skynet.send(handle, "lua", "write_user", user)
end

function _M.write_zset(tname, data)
	local handle = get_address()
	skynet.send(handle, "lua", "write_zset", tname, data)
end

return _M
