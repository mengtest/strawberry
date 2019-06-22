local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local query = require "chestnut.query"
local util = require "chestnut.time"
local dbmonitor = require "dbmonitor"

local CLS_NAME = "recordmgr"

local cls = class(CLS_NAME)

function cls:ctor(context, ... )
	-- body
	cls.super.ctor(self, context)
	self.agentContext = context
	self.agentSystems = nil
	self.dbRecord = nil
	return self
end

function cls:on_data_init(dbData)
 	-- body
end

function cls:on_data_save(dbData)
end

function cls:inituser( ... )
	-- body
	self:send_records()
end

function cls:send_records( ... )
	-- body
	local l = {}
	for _,v in pairs(self._mk) do
		if v.viewed.value == 0 then
			local r = {}
			r.id       = v.mailid
			r.viewed   = v.viewed
			r.title    = t.title
			r.content  = t.content
			r.datetime = t.datetime
			table.insert(l, mail)
		end
	end

	local args = {}
	args.l = l
	self.context:send_request("records", args)
end

function cls:send_record( ... )
	-- body
end

function cls:add(item, ... )
	-- body
	table.insert(self._data, mail)
	self._count = self._count + 1
	self._mk[item.id.value] = item
end

function cls:create(recordid, names, ... )
	-- body
	local r = record.new(self._env, self._dbctx, self)
	r.id.value = recordid
	r.uid = self._env._suid
	r.datetime = os.time()
	r.player1 = names[1]
	r.player2 = names[2]
	r.player3 = names[3]
	r.player4 = names[4]
	return r
end

function cls:add(mail, ... )
	-- body
	table.insert(self._data, mail)
	self._count = self._count + 1
	self._mk[mail.mailid.value] = mail
end

function cls:records(args, ... )
	-- body
	local res = {}
	res.errorcode = errorcode.SUCCESS
	res.records = {}
	for i,v in ipairs(self._mk) do
		local record = {}
		record.id       = v.recordid
		record.datetime = v.datetime
		record.player1  = v.player1
		record.player2  = v.player2
		record.player3  = v.player3
		record.player4  = v.player4
		table.insert(res.records, record)
	end
	return res
end

function cls:record(recordid, names, ... )
	-- body
	local i = record.new(self._env, self._dbctx, self)
	i.uid.value = self._env._suid
	i.recordid = recordid
	i.datetime = os.time()
	i.player1 = names[1]
	i.player2 = names[2]
	i.player3 = names[3]
	i.player4 = names[4]
	i:insert_db()
end

return cls