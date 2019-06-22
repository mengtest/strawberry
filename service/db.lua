local skynet = require "skynet"
require "skynet.manager"
local mysql = require "skynet.db.mysql"
local log = require "chestnut.skynet.log"
local db_read = require "db.db_read"
local db_write = require "db.db_write"
local traceback = debug.traceback
local assert = assert

local mode = ...

if mode == "agent" then

local db
local ctx

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

local function connect_mysql()
	local function on_connect( db )
		db:query( "set charset utf8" )
	end
	local c = {
		host = skynet.getenv("db_host") or "127.0.0.1",
		port = skynet.getenv("db_port") or 3306,
		database = skynet.getenv("db_database") or "user",
		user = skynet.getenv("db_user") or "root",
		password = skynet.getenv("db_password") or "123456",
		max_packet_size = 1024 * 1024,
		on_connect = on_connect,
	}
	return mysql.connect(c)
end

local function disconnect_mysql( ... )
	-- body
	if db then
		db:disconnect()
	end
end

local QUERY = {}

function QUERY.close()
	-- body
	disconnect_mysql()
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
function QUERY.write_new_account(db_account)
	db_write.write_account(ctx, db_account)
	return true
end

function QUERY.write_new_user(db_user)
	-- body
	db_write.write_user(ctx, db_user)
	return true
end

function QUERY.write_user(data)
	-- body
	db_write.write_user(ctx, data.db_user)
	db_write.write_user_room(ctx, data.db_user_room)
	db_write.write_user_package(ctx, data.db_user_package)
	db_write.write_user_funcopen(ctx, data.db_user_funcopens)
	return true
end

function QUERY.write_room_mgr(data)
	-- body
	db_write.write_room_mgr_users(ctx, data.db_users)
	db_write.write_room_mgr_rooms(ctx, data.db_rooms)
	return true
end

function QUERY.write_room(data)
	-- body
	db_write.write_room_users(ctx, data.db_users)
	db_write.write_room(ctx, data.db_room)
	return true
end

------------------------------------------
-- 修改离线数据
function QUERY.write_offuser_room(db_user_room)
	-- body
	db_write.write_offuser_room_created(ctx, db_user_room)
	return true
end

-------------------------------------------------------------end

skynet.start(function ()
	-- body
	db = connect_mysql()
	ctx = { db=db, dump=dump }
	skynet.dispatch( "lua" , function( _, _, cmd, ... )
		local f = assert(QUERY[cmd])
		local ok, err = xpcall(f, traceback, ...)
		if ok then
			assert(err)
			skynet.retpack(err)
		else
			log.error(err)
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
	skynet.dispatch( "lua" , function( _, _, ... )
		local r = skynet.call(agent[balance], "lua", ... )
		skynet.retpack(r)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
	skynet.register ".DB"
end)

end