local log = require "chestnut.skynet.log"
local table_dump = require "luaTableDump"
local string_format = string.format

local _M = {}

function _M:read_sysmail()
	-- body
	local res = self.db:query('SELECT * FROM tb_sysmail;')
	return res
end

function _M:read_room_mgr_users()
	-- body
	local res = self.db:query("CALL sp_room_mgr_users_select();")
	if res.errno then
		log.error('%s', self.dump(res))
		return res
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

function _M:read_room_mgr_rooms()
	-- body
	local res = self.db:query('CALL sp_room_mgr_rooms_select();')
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

function _M:read_account_by_username(username, password)
	-- body
	local res = self.db:query(string.format("CALL sp_account_select('%s', '%s');", username, password))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return {}
end

function _M:read_room(id)
	-- body
	local res = self.db:query(string_format("CALL sp_room_select(%d);", id))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return {}
end

function _M:read_room_users(id)
	-- body
	local res = self.db:query(string_format("CALL sp_room_users_select(%d);", id))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	else
		return {}
	end
end

------------------------------------------
-- about user
function _M:read_users_by_uid(uid)
	-- body
	local res = self.db:query(string_format("CALL sp_user_select(%d);", uid))
	-- print(self.dump(res))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

function _M:read_user_rooms(uid)
	-- body
	local res = self.db:query(string_format("CALL sp_user_room_select(%d);", uid))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

function _M:read_user_packages(uid)
	-- body
	local res = self.db:query(string_format("CALL sp_user_package_select(%d);", uid))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

function _M:read_user_funcopens(uid)
	-- body
	local res = self.db:query(string_format("CALL sp_user_funcopen_select(%d);", uid))
	if res.errno then
		log.error('%s', self.dump(res))
		return {}
	end
	if res.multiresultset then
		return res[1]
	end
	return res
end

return _M