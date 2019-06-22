local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local zset = require "chestnut.zset"
local query = require "chestnut.query"
local sysmaild = require "sysmaild"
local client = require "client"


local function send_inbox_list(obj, ... )
	-- body
	local l = {}
	for _,v in pairs(self._mk) do
		if v.viewed.value == 0 then
			local mail = {}
			mail.id       = v.mailid
			mail.viewed   = v.viewed
			mail.title    = t.title
			mail.content  = t.content
			mail.datetime = t.datetime
			table.insert(l, mail)
		end
	end

	local args = {}
	args.l = l
	client.push(obj, "inbox", args)
end

local cls = {}

function cls:on_data_init(dbData, ... )
end

function cls:on_data_save(dbData, ... )
	-- body
end

function cls:on_enter( ... )
	-- body
	send_inbox_list(self)
end

function cls:on_exit( ... )
	-- body
end

function cls:add(mail, ... )
	-- body
	table.insert(self._data, mail)
	self._count = self._count + 1
	self._mk[mail.mailid.value] = mail
	self._mkzs:add(1, string.format("%d", mail.id.value))
end

function cls:poll( ... )
	-- body
	skynet.fork(function ( ... )
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
	end)
end

function cls:send_inbox(id, ... )
	-- body
	local v = assert(self._mk[id])
	local l = {}
	local mail = {}
	mail.id       = v.mailid
	mail.viewed   = v.viewed
	mail.title    = t.title
	mail.content  = t.content
	mail.datetime = t.datetime
	table.insert(l, mail)
	local args = {}
	args.l = l
	self.context:send_request("inbox", args)
end

local CH = client.request()

function CH:fetch(args, ... )
	-- body
	log.info("sysinbox fetch")
	local res = {}
	res.errorcode = errorcode.SUCCESS
	res.inbox = {}
	for k,v in pairs(self._mk) do
		if v.viewed.value == 0 then
			local mail = {}
			mail.id = v.mailid.value
			mail.viewed = v.viewed.value
			local t = sd.query(string.format("%s:%d", self._tname, v.mailid))
			mail.title    = t.title
			mail.content  = t.content
			mail.datetime = t.datetime
			table.insert(res.inbox, mail)
		end
	end
	return res
end

function CH:sync(args, ... )
	-- body
	log.info("sysinbox sync")
	local res = {}
	res.errorcode = errorcode.SUCCESS
	res.inbox = {}
	for k,v in pairs(self._data) do
		if v.viewed.value == 0 then
			local mail = {}
			mail.id = v.mailid.value
			mail.datetime = v.datetime.value
			mail.viewed = v.viewed.value
			local t = sd.query(string.format("tg_sysmail:%d", v.mailid.value))
			mail.title   = t.title
			mail.content = t.content
			table.insert(res.inbox, mail)
		end
	end
	return res
end

function CH:viewed(args, ... )
	-- body
	local mail = self._mk[args.mailid]
	mail:set_viewed(1)
	local res = {}
	res.errorcode = errorcode.SUCCESS
	return res
end

function CMD.aa( ... )
	-- body
end

return cls