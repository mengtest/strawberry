local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local agent_mgr = require "chestnut.agent_mgr.c"
local sysmaild = require "sysmaild"
local client = require "client"
local objmgr = require "objmgr"
local _M = {}

local function send_inbox_list(obj, ...)
	local l = {}
	for _, v in pairs(self._mk) do
		if v.viewed.value == 0 then
			local mail = {}
			mail.friend_uid = v.friend_uid
			mail.viewed = v.viewed
			mail.title = t.title
			mail.content = t.content
			mail.datetime = t.datetime
			table.insert(l, mail)
		end
	end

	local args = {}
	args.l = l
	client.push(obj, "inbox", args)
end

skynet.init(
	function()
		-- body
	end
)

function _M.on_data_init(self, dbData)
	self.mod_friend = {friends = {}, friend_reqs = {}}
	local db_friends = dbData.db_friends
	local db_friend_reqs = dbData.db_friend_reqs
	for _, db_item in pairs(db_friends) do
		local item = {}
		item.friend_uid = assert(db_item.friend_uid)
		item.alias = assert(db_item.alias)
		item.deled = assert(db_item.deled)
		self.mod_friend.friends[tonumber(item.friend_uid)] = item
	end
	for _, db_item in pairs(db_friend_reqs) do
		local item = {}
		item.id = assert(db_item.id)
		item.from_uid = assert(db_item.from_uid)
		item.accept = assert(db_item.accept)
		self.mod_friend.friend_reqs[item.id] = item
	end
end

function _M.on_data_save(self, dbData)
	dbData.db_friends = {}
	dbData.db_friend_reqs = {}
	for _, item in pairs(self.mod_friend.friends) do
		local db_item = {}
		db_item.uid = self.uid
		db_item.friend_uid = item.friend_uid
		db_item.alias = item.alias
		db_item.deled = item.deled
		table.insert(dbData.db_friends, db_item)
	end
	for _, item in pairs(self.mod_friend.friend_reqs) do
		local db_item = {}
		db_item.id = item.id
		db_item.to_uid = self.uid
		db_item.from_uid = item.from_uid
		db_item.accept = item.accept
		table.insert(dbData.db_friend_reqs, db_item)
	end
end

function _M.on_enter(self)
	send_inbox_list(self)
end

function _M.on_exit(self)
end

function _M.fetch_friends(fd, args)
	local obj = objmgr.get_by_fd(fd)
	return {errorcode = 0}
end

function _M.fetch_friend(fd, args)
	local obj = objmgr.get_by_fd(fd)
	local friend_uid = args.friend_uid
	local friend = obj.mod_friend.friends[friend_uid]
	if friend then
		return {errorcode = 0}
	end
	return {errorcode = 1}
end

function _M.rm_friend(fd, args)
	local obj = objmgr.get_by_fd(fd)
	local friend_uid = args.friend_uid
	local friend = obj.mod_friend.friends[friend_uid]
	if friend then
		friend.deled = 1
		return {errorcode = 0}
	end
	return {errorcode = 1}
end

-- 向朋友发出请求
function _M.add_friend_req(fd, args)
	local obj = objmgr.get_by_fd(fd)
	local friend_uid = args.friend_uid
	local code = agent_mgr.add_friend_req(friend_uid, obj.uid)
	if code == 0 then
	else
		-- 插入离线用户好友请求
	end
	return {errorcode = 1}
end

-- 自己的好友请求
function _M.fetch_friend_reqs(fd, args)
	local obj = objmgr.get_by_fd(fd)
	return {errorcode = 1}
end

function _M.acc_friend_req(fd, args)
	local obj = objmgr.get_by_fd(fd)
	local friend_req = obj.mod_friend.friend_reqs[args.id]
	if friend_req then
		friend_req.accept = 1
		return {errorcode = 1}
	end
	return {errorcode = 1}
end

function _M.rej_friend_req(fd, args)
	local obj = objmgr.get_by_fd(fd)
	local friend_req = obj.mod_friend.friend_reqs[args.id]
	if friend_req then
		friend_req.accept = 2
		return {errorcode = 1}
	end
	return {errorcode = 1}
end

function _M.acc_friend_req_all(fd, args)
	local obj = objmgr.get_by_fd(fd)
	for _, friend_req in pairs(obj.mod_friend.friend_reqs) do
		friend_req.accept = 1
	end
	return {errorcode = 1}
end

function _M.rej_friend_req_all(fd, args)
	local obj = objmgr.get_by_fd(fd)
	for _, friend_req in pairs(obj.mod_friend.friend_reqs) do
		friend_req.accept = 2
	end
	return {errorcode = 1}
end

return _M
