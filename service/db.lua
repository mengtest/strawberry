local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local db_read = require "db.db_read"
local db_write = require "db.db_write"
local util = require 'db.util'
local traceback = debug.traceback
local assert = assert

local mode = ...

if mode == "agent" then

local db
local ctx

local QUERY = {}

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
function QUERY.read_sysmail()
	-- body
	local res = db_read.read_sysmail(ctx)
	return res
end

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

function QUERY.read_user(uid)
	-- body
	local res = {}
	res.db_users = db_read.read_users_by_uid(ctx, uid)
	res.db_user_rooms = db_read.read_user_rooms(ctx, uid)
	res.db_user_packages = db_read.read_user_packages(ctx, uid)
	res.db_user_funcopens = db_read.read_user_funcopens(ctx, uid)
	return res
end

function QUERY.read_room_mgr()
	-- body
	local res = {}
	res.db_users = db_read.read_room_mgr_users(ctx)
	res.db_rooms = db_read.read_room_mgr_rooms(ctx)
	return res
end

function QUERY.read_room(id)
	-- body
	local res = {}
	res.db_rooms = db_read.read_room(ctx, id)
	res.db_users = db_read.read_room_users(ctx, id)
	return res
end

------------------------------------------
-- 写数据
function QUERY.write_account(db_account)
	db_write.write_account(ctx, db_account)
end

function QUERY.write_union(db_union)
	-- body
end

function QUERY.write_user(db_user)
	-- body
	db_write.write_user(ctx, db_user)
end

function QUERY.write_user(data)
	-- body
	db_write.write_user(ctx, data.db_user)
	db_write.write_user_room(ctx, data.db_user_room)
	db_write.write_user_package(ctx, data.db_user_package)
	db_write.write_user_funcopen(ctx, data.db_user_funcopens)
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

------------------------------------------
-- 修改离线数据
function QUERY.write_offuser_room(db_user_room)
	-- body
	db_write.write_offuser_room_created(ctx, db_user_room)
end

-------------------------------------------------------------end

skynet.start(function ()
	-- body
	db = util.connect_mysql()
	ctx = { db=db, dump= util.dump }
	skynet.dispatch( "lua" , function( _, _, cmd, ... )
		local f = assert(QUERY[cmd])
		local ok, err = xpcall(f, traceback, ...)
		if ok then
			if err then
				skynet.retpack(err)
			end
		else
			log.error('db agent cmd = [%s], err = %s', cmd, err)
		end
	end)
end)

else

skynet.start(function ()
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	skynet.dispatch( "lua" , function( _, _, cmd, ... )
		local d = cmd:sub(1, 1)
		if d == 'r' then
			local r = skynet.call(agent[balance], "lua", cmd, ... )
			assert(r)
			skynet.retpack(r)
			balance = balance + 1
			if balance > #agent then
				balance = 2
			end
		elseif d == 'w' then
			skynet.send(agent[1], "lua", cmd, ... )
		end
	end)
	skynet.register ".DB"
end)

end