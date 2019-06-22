local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local time_utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local servicecode = require "enum.servicecode"
local client = require "client"
local AgentSystems = require "chestnut.agent.AgentSystems"
local pcall = pcall
local assert = assert

local REQUEST = client.request()

function REQUEST:handshake()
	-- body
	local login_type = skynet.getenv 'login_type'
	if login_type == 'so' then
		self:send_request("handshake")
	else
		self:send_request_gate("handshake")
	end
	local res = {}
	res.errorcode = 0
	return res
end

function REQUEST:enter()
	-- body
	log.info('test enter')
	AgentSystems.on_enter(self)
	return { errorcode = 1 }
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

function REQUEST:viewedsysmail(args, ... )
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

function REQUEST:room_info(args)
	-- body
	local ok, err = pcall(self.systems.room.room_info, self.systems.room, args)
	if ok then
		return err
	else
		log.error("uid(%d) REQUEST = [room_info], error = [%s]", self.uid, err)
		local res = {}
		res.errorcode = 1
		return res
	end
end

function REQUEST:package_info(args)
	-- body
	return self.systems.package:package_info(args)
end

------------------------------------------
-- 麻将协议
function REQUEST:match(args)
	-- body
	return self.systems.room:match(args)
end

function REQUEST:create(args)
	-- body
	local M = self.systems.room
	return M:create(args)
end

function REQUEST:join(args)
	-- body
	local M = self.systems.room
	return M:join(args)
end

function REQUEST:rejoin()
	-- body
	return self.systems.room:rejoin()
end

function REQUEST:leave(args)
	-- body
	local M = self.systems.room
	return M:leave(args)
end

function REQUEST:ready(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("ready", args, ...)
end

function REQUEST:call(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("call", args, ...)
end

-- 此协议已经无效
function REQUEST:shuffle(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("shuffle", args, ...)
end

-- 此协议已经无效
function REQUEST:dice(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("dice", args, ...)
end

function REQUEST:lead(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("lead", args, ...)
end

function REQUEST:step(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("step", args, ...)
end

function REQUEST:restart(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("restart", args, ...)
end

function REQUEST:xuanpao(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("xuanpao", args, ...)
end

function REQUEST:xuanque(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("xuanque", args, ...)
end

------------------------------------------
-- 大佬2协议
function REQUEST:big2call( ... )
	-- body
	return self.systems.room:forward_room("call", ...)
end

function REQUEST:big2step( ... )
	-- body
	return self.systems.room:forward_room("step", ...)
end

function REQUEST:big2restart( ... )
	-- body
	return self.systems.room:forward_room("restart", ...)
end

function REQUEST:big2ready( ... )
	-- body
	return self.systems.room:forward_room("ready", ...)
end

function REQUEST:big2match( ... )
	-- body
	return self.systems.room:match(...)
end

function REQUEST:big2create( ... )
	-- body
	return self.systems.room:create(...)
end

function REQUEST:big2join( ... )
	-- body
	return self.systems.room:join(...)
end

function REQUEST:big2rejoin( ... )
	-- body
	return self.systems.room:rejoin(...)
end

function REQUEST:big2leave( ... )
	-- body
	return self.systems.room:leave(...)
end

------------------------------------------
-- 房间聊天协议
function REQUEST:rchat(args, ... )
	-- body
	local M = self.systems.room
	return M:forward_room("rchat", args, ...)
end

------------------------------------------
-- 德州协议
function REQUEST:pokercall( ... )
	-- body
	return self.systems.room:forward_room("call", ...)
end

function REQUEST:pokerstep( ... )
	-- body
	return self.systems.room:forward_room("step", ...)
end

function REQUEST:pokerrestart( ... )
	-- body
	return self.systems.room:forward_room("restart", ...)
end

function REQUEST:pokerready( ... )
	-- body
	return self.systems.room:forward_room("ready", ...)
end

function REQUEST:pokermatch( ... )
	-- body
	return self.systems.room:match(...)
end

function REQUEST:pokercreate( ... )
	-- body
	return self.systems.room:create(...)
end

function REQUEST:pokerjoin( ... )
	-- body
	return self.systems.room:join(...)
end

function REQUEST:pokerrejoin( ... )
	-- body
	return self.systems.room:rejoin(...)
end

function REQUEST:pokerleave( ... )
	-- body
	return self.systems.room:leave(...)
end

function REQUEST:pokerjoined( ... )
	-- body
	return self.systems.room:forward_room("joined", ...)
end

return REQUEST