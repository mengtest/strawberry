local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local time_utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local AgentSystems = require "chestnut.agent.systems"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST:handshake()
	-- body
	-- skynet.error('handshake')
	log.info("test handshake")
	local obj = self.obj
	client.push(obj, "handshake")
	local res = {}
	res.errorcode = 0
	return res
end

function REQUEST:enter()
	local ok, err = xpcall(AgentSystems.on_enter, traceback, self.obj)
	if not ok then
		log.error(err)
		return {errorcode = 1}
	end
	return {errorcode = 0}
end

function REQUEST:logout()
	-- body
	local res = {}
	if logout.logout(self) == servicecode.SUCCESS then
		res.errorcode = 0
	else
		res.errorcode = 1
	end
	return res
end

------------------------------------------
-- 系统模块
function REQUEST:first(args)
	-- body
	local ok, err = pcall(self.systems.user.first, self.systems.user, args)
	if ok then
		return err
	else
		log.error("uid(%d) REQUEST = [first], error = [%s]", self.uid, err)
		local res = {}
		res.errorcode = 1
		return res
	end
end

-- 检测今天是否签到
function REQUEST:checkindaily(args)
	-- body
	local res = {}
	local cds, day = time_utils.cd_sec()
	if u.checkin_lday.value == cds then
		res.errorcode = 1
		return res
	else
		local cnt = self._user.checkin_count.value
		cnt = cnt + 1
		self._user:set_checkin_count(cnt)
		self._user:update_db("tg_users", 7)
		local mcnt = set._user.checkin_mcount.value
		mcnt = mcnt + 1
		self._user:set_checkin_mcount(mcnt)
		self._user:update_db("tg_users", 8)
	end
	res.errorcode = 0
	return res
end

function REQUEST:board(args)
	-- body
	assert(self)
	return skynet.call(".ONLINE_MGR", "lua", "toast1", args)
end

function REQUEST:adver(args)
	-- body
	assert(self)
	return skynet.call(".ONLINE_MGR", "lua", "toast2", args)
end

function REQUEST:fetchinbox(args)
	-- body
	local M = self.modules.inbox
	return M:fetch(args)
end

function REQUEST:syncsysmail(args)
	-- body
	return self._sysinbox:sync(args)
end

function REQUEST:viewedsysmail(args, ...)
	-- body
	local entity = self:get_entity()
	local sysinbox = entity:get_component("sysinbox")
	return sysinbox:viewed(args)
end

function REQUEST:records(args)
	-- body
	assert(self)
	-- local M = self.modules.recordmgr
	-- return M:records(args)
end

function REQUEST:record(args)
	-- body
	assert(self)
end

function REQUEST:package_info(args)
	-- body
	return self.systems.package:package_info(args)
end

return REQUEST
