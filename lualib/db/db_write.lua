local log = require "chestnut.skynet.log"
local string_format = string.format
local _M = {}

function _M:write_room_mgr_users(db_users)
	-- body
	for _, db_user in pairs(db_users) do
		local sql = string_format([==[CALL
		sp_room_mgr_users_insert_or_update(%d, %d);]==], db_user.uid, db_user.roomid)
		-- log.info(sql)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
	return true
end

function _M:write_room_mgr_rooms(db_rooms)
	-- body
	for _, db_room in pairs(db_rooms) do
		local sql =
			string_format(
			[==[CALL
			sp_room_mgr_rooms_insert_or_update(%d, %d, '%s', %d, %d, %d);]==],
			db_room.id,
			db_room.host,
			db_room.users,
			db_room.ju,
			db_room.mode,
			db_room.type
		)
		local res = self.db:query(sql)
		if res.errno then
			log.error(sql)
			log.error("%s", self.dump(res))
		end
	end
	return true
end

function _M:write_room_users(db_users)
	-- body
	for _, db_user in pairs(db_users) do
		local sql =
			string_format(
			[==[CALL
			sp_room_users_insert_or_update(%d, %d, '%s', %d, %d);]==],
			db_user.uid,
			db_user.roomid,
			db_user.state,
			db_user.idx,
			db_user.chip
		)
		-- log.info(sql)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
		end
	end
	return true
end

function _M:write_room(db_room)
	-- body
	local sql =
		string_format(
		[==[CALL
		sp_room_insert_or_update(%d, %d, %d, %d, %d, '%s');]==],
		db_room.id,
		db_room.type,
		db_room.mode,
		db_room.host,
		db_room.open,
		db_room.rule
	)
	local res = self.db:query(sql)
	if res.errno then
		log.error(sql)
		log.error("%s", self.dump(res))
	end
	return true
end

function _M:write_zset(tname, data)
	if tname == "power" then
		for _, it in pairs(data) do
			local sql = string_format([==[CALL
				sp_zset_power_insert_or_update(%d, %d, %d);]==], it.id, it.uid, it.power)
			local res = self.db:query(sql)
			if res.errno then
				log.error(sql)
				log.error("%s", self.dump(res))
			end
		end
	end
end

------------------------------------------
-- about user
function _M:write_account(db_account)
	local sql =
		string_format(
		[==[CALL
		sp_account_insert_or_update('%s', '%s', %d);]==],
		db_account.username,
		db_account.password,
		db_account.uid
	)
	local res = self.db:query(sql)
	if res.errno then
		log.error("%s", self.dump(res))
	end
	return res
end

function _M:write_user(db_user)
	local sql =
		string_format(
		[==[CALL
		sp_user_insert_or_update(%d, %d, '%s', '%s', '%s', '%s', '%s', '%s', '%s', %d, %d, %d, %d);]==],
		db_user.uid,
		db_user.sex,
		db_user.nickname,
		db_user.province,
		db_user.city,
		db_user.country,
		db_user.headimg,
		db_user.openid,
		db_user.nameid,
		db_user.login_at,
		db_user.new_user,
		db_user.level,
		db_user.exp
	)
	log.info(sql)
	local res = self.db:query(sql)
	if res.errno then
		log.error("%s", self.dump(res))
	end
end

function _M:write_user_room(db_user_room)
	-- body
	if not db_user_room then
		return
	end
	local sql =
		string_format(
		[==[CALL
		sp_user_room_insert_or_update(%d, %d, %d, %d, %d, %d);]==],
		db_user_room.uid,
		db_user_room.roomid,
		db_user_room.created,
		db_user_room.joined,
		db_user_room.mode,
		db_user_room.type
	)
	local res = self.db:query(sql)
	if res.errno then
		log.error(sql)
		log.error("%s", self.dump(res))
	end
end

function _M:write_user_package(db_user_package)
	if not db_user_package then
		return
	end
	for _, db_user_item in ipairs(db_user_package) do
		local sql =
			string_format(
			[==[CALL
			sp_user_package_insert_or_update(%d, %d, %d);]==],
			db_user_item.uid,
			db_user_item.id,
			db_user_item.num
		)
		-- log.info(sql)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
end

function _M:write_user_funcopen(db_user_funcopens)
	if not db_user_funcopens then
		return
	end
	for _, db_user_funcitem in ipairs(db_user_funcopens) do
		local sql =
			string_format(
			[==[CALL
			sp_user_funcopen_insert_or_update(%d, %d, %d);]==],
			db_user_funcitem.uid,
			db_user_funcitem.id,
			db_user_funcitem.open
		)
		-- log.info(sql)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			break
		end
	end
end

function _M:write_user_achievement(data)
	if not data then
		return
	end
	for _, item in ipairs(data) do
		local sql =
			string_format(
			[==[CALL
			sp_user_achievement_insert_or_update(%d, %d, %d, %d);]==],
			item.uid,
			item.id,
			item.reach,
			item.recv
		)
		-- log.info(sql)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
end

function _M:write_user_heros(data)
	if not data then
		return
	end
	for _, item in ipairs(data) do
		local sql =
			string_format([==[CALL
			sp_user_heros_insert_or_update(%d, %d, %d);]==], item.uid, item.hero_id, item.level)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
end

function _M:write_user_friends(data)
	if not data then
		return
	end
	for _, item in ipairs(data) do
		local sql =
			string_format([==[CALL
			sp_user_firends_insert_or_update(%d, %d, %d);]==], item.uid, item.hero_id, item.level)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
end

function _M:write_user_friends(data)
	if not data then
		return
	end
	for _, item in ipairs(data) do
		local sql =
			string_format(
			[==[CALL
			sp_user_firend_reqs_insert_or_update(%d, %d, %d);]==],
			item.id,
			item.to_id,
			item.from_id,
			item.accept
		)
		local res = self.db:query(sql)
		if res.errno then
			log.error("%s", self.dump(res))
			return false
		end
	end
end

------------------------------------------
-- 离线用户数据
function _M:write_offuser_room_created(db_user_room)
	-- body
	local sql =
		string_format(
		[==[CALL
	sp_offuser_room_update_created(%d, %d, %d, %d);]==],
		db_user_room.uid,
		db_user_room.created,
		db_user_room.joined,
		db_user_room.mode
	)
	-- log.info(sql)
	local res = self.db:query(sql)
	if res.errno then
		log.error("%s", self.dump(res))
	end
	return true
end

return _M
