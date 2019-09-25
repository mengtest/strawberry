local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local agent_mgr = require "chestnut.agent_mgr.c"
local sysmaild = require "sysmaild"
local client = require "client"
local _M = {}

local function send_inbox_list(obj, ...)
	local l = {}
	for _, v in pairs(self._mk) do
		if v.viewed.value == 0 then
			local mail = {}
			mail.id = v.mailid
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
	local db_friends = dbData.db_friends
	for _, db_item in pairs(db_friends) do
		local item = {}
		item.id = assert(db_item.id)
		item.num = assert(db_item.num)
		item.createAt = assert(db_item.create_at)
		item.updateAt = assert(db_item.update_at)
		package[tonumber(item.id)] = item
	end
end

function _M.on_data_save(self, dbData)
end

function _M.on_enter(self)
	send_inbox_list(self)
end

function _M.on_exit(self)
end

function _M.fetch_friends(obj, args)
	return {errorcode = 0}
end

function _M.fetch_friend(obj, args)
	local friend_uid = args.friend_uid
end

function _M.rm_friend(obj, args)
	local friend_uid = args.friend_uid
end

-- 向朋友发出请求
function _M.add_friend_req(obj, args)
end

-- 自己的好友请求
function _M.fetch_friend_reqs(obj, args)
end

function _M.acc_friend_req(obj, args)
end

function _M.rej_friend_req(obj, args)
end

function _M.acc_friend_req_all(obj, args)
end

function _M.rej_friend_req_all(obj, args)
end

return _M
