local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local AgentSystems = require "chestnut.agent.AgentSystems"
local servicecode = require "enum.servicecode"
local CMD = require "chestnut.agent.cmd"
local request = require "chestnut.agent.request"
local logout = require "chestnut.agent.logout"
local savedata = require "savedata"
local objmgr = require "objmgr"
local assert = assert
local traceback = debug.traceback
local reload = false

local function init_data(obj)
	-- body
	local uid = obj.uid
	log.info("uid(%d) load_cache_to_data", uid)
	local res = skynet.call(".DB", "lua", "read_user", uid)
	-- init user
	local ok, err = xpcall(AgentSystems.on_data_init, traceback, obj, res)
	if not ok then
		log.error(err)
		return servicecode.LOGIN_AGENT_LOAD_ERR
	end
	return servicecode.SUCCESS
end

local function save_data(uid)
	-- body
	objmgr.foreach(function (obj, ... )
		-- body
		
	end)
	-- local data = {}
	-- local ok, err = xpcall(self.systems.on_data_save, traceback, self.systems, data)
	-- if not ok then
	-- 	log.error(err)
	-- else
	-- 	skynet.call(".DB", "lua", "write_user", data)
	-- end
end

local cls = {}

local SUB = {}

function SUB.save_data( ... )
	-- body
	save_data()
end

function cls.start(channel_id, ... )
	-- body
	savedata.init({
		command=SUB
	})
	return true
end

function cls.init_data( ... )
	-- body
	return true
end

function cls.sayhi(reload)
	-- body
	return true
end

function cls.close( ... )
	-- body
	self:save_data()
	return cls.super.close(self, ... )
end

function cls.kill( ... )
	-- body
end

function cls.login(gate, uid, subid, secret)
	local obj = objmgr.get(uid)
	if obj then
		obj.subid = subid
		if not obj.loaded then
			-- 加载数据
			-- TODO:
			init_data(obj)
			obj.loaded = true
		end
	else
		obj = objmgr.new_obj()
		obj.gate = gate
		obj.uid = uid
		obj.subid = subid
		obj.secret = secret
		obj.logined = true
		obj.authed = false
		objmgr.add(uid, obj)
		-- TODO:
		init_data(obj)
		obj.logined = true
		savedata.subscribe()
	end
	return servicecode.SUCCESS
end

function cls.logout(uid, ... )
	-- body
	local obj = objmgr.get(uid)
	assert(obj.logined)
	assert(obj.authed)
	save_data(uid)

	local ok = skynet.call(".AGENT_MGR", "lua", "exit_at_once", obj.uid)
	if not ok then
		log.error("call agent_mgr exit_at_once failture.")
		return servicecode.FAIL
	end

	obj.authed = false
	obj.logined = false
	log.info("uid(%d) agent logout", obj.uid)
	return servicecode.SUCCESS
end

function cls.auth(args)
	-- body
	-- if not self.channelSubscribed then
	-- 	log.info("uid(%d) subscribe channel_id", self.uid)
	-- 	self.channelSubscribed = true
	-- 	self.channel:subscribe()
	-- end
	local obj = assert(objmgr.get(args.uid))
	obj.fd = args.client
	obj.authed = true
	objmgr.addfd(args.client, obj)
	return true
end

function cls.afk(fd)
	-- body
	log.info('agent fd(%d) afk', fd)
	local obj = objmgr.get_by_fd(fd)
	return logout.logout(obj)
end

return setmetatable({}, { __index = function (t, cmd, uid, ...) 
	return function (uid, ...)
		if cls[cmd] then
			return cls[cmd](uid, ...)
		else
			local obj = assert(objmgr.get(uid))
			local f = assert(CMD[cmd])
			return f(obj, ...)
		end
	end
end})
