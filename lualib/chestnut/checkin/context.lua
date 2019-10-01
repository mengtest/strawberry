local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local sysmaild = require "sysmaild"
local client = require "client"
local servicecode = require "enum.servicecode"
local _M = {}

local function send_inbox_list(obj, ...)
	-- body
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
	end
)

function _M.on_data_init(self, dbData)
end

function _M.on_data_save(self, dbData)
end

function _M.on_enter(self)
	send_inbox_list(self)
end

function _M.on_exit(self)
end

function _M.add(self, mail, ...)
	table.insert(self._data, mail)
	self._count = self._count + 1
	self._mk[mail.mailid.value] = mail
	self._mkzs:add(1, string.format("%d", mail.id.value))
end

function _M.poll(...)
	skynet.fork(
		function(...)
			-- body
			-- local res
			-- if self._count > 0 then
			-- 	res = sysmaild.poll(self._mkzs:range(self._mkzs:count() - 1, self._mkzs:count())[1])
			-- else
			-- 	res = sysmaild.poll(0)
			-- end
			-- log.info("sysinbox poll %d", #res)
			-- for _,mailid in pairs(res) do
			-- 	local i = sysmail.new(self._env, self._dbctx, self)
			-- 	i.id.value = snowflake.next_id()
			-- 	i.uid.value = self._env._suid
			-- 	i.mailid.value = math.tointeger(mailid)
			-- 	i.viewed.value = 0
			-- 	i:insert_cache()
			-- 	self:add(i)
			-- end
		end
	)
end

function _M.send_inbox(id, ...)
	-- body
	local v = assert(self._mk[id])
	local l = {}
	local mail = {}
	mail.id = v.mailid
	mail.viewed = v.viewed
	mail.title = t.title
	mail.content = t.content
	mail.datetime = t.datetime
	table.insert(l, mail)
	local args = {}
	args.l = l
	self.context:send_request("inbox", args)
end

function _M.fetch_checkins(fd, args)
end

return _M
