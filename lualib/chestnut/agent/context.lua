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
local dbc = require 'db.db'
local command = require 'command'
local _M = command.cmd1()
local SUB = {}
local assert = assert
local traceback = debug.traceback
local _reload = false

local function init_data(obj)
	-- body
	local uid = obj.uid
	log.info("uid(%d) load_cache_to_data", uid)
	local res = dbc.read_user(uid)
	-- init user
	local ok, err = xpcall(AgentSystems.on_data_init, traceback, obj, res)
	if not ok then
		log.error(err)
		return servicecode.LOGIN_AGENT_LOAD_ERR
	end
	return servicecode.SUCCESS
end

local function save_data()
	-- body
	objmgr.foreach(function (obj, ... )
		-- body
		if obj.authed then
			local data = {}
			local ok, err = xpcall(AgentSystems.on_data_save, traceback, obj, data)
			if ok then
				if table.length(data) > 0 then
					dbc.write_user(data)
				end
			else
				log.error(err)
			end
		end
	end)
end

skynet.init(function ()
	-- body
end)

function SUB.save_data( ... )
	-- body
	save_data()
end

function _M.start()
	-- body
	savedata.init({
		command=SUB
	})
	return true
end

function _M.init_data()
	-- body
	return true
end

function _M.sayhi(reload)
	-- 重连的时候，auth函数用此判断
	_reload = reload
	return true
end

function _M.close()
	-- body
	return true
end

function _M.kill()
	-- body
end

function _M.login(gate, uid, subid, secret)
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
		objmgr.add(obj)
		-- TODO:
		init_data(obj)
		savedata.subscribe()
	end
	return servicecode.SUCCESS
end

-- call by gated
function _M.logout(uid)
	-- body
	local obj = objmgr.get(uid)
	assert(obj.logined)
	assert(obj.authed)
	save_data(uid)

	-- 断线重连
	if false then
		obj.logined = false
		obj.authed = false
		return skynet.call(".AGENT_MGR", "lua", "exit", obj.uid)
	else
		local err = skynet.call(".AGENT_MGR", "lua", "exit_at_once", obj.uid)
		if err == servicecode.SUCCESS then
			objmgr.del(obj)
			log.info("uid(%d) agent logout", obj.uid)
		end
		return err
	end
	return servicecode.SUCCESS
end

-- call by agent mgr
function _M.kill_cache(uid)
	-- body
	local obj = objmgr.get(uid)
	assert(obj)
	objmgr.del(obj)
	log.info("uid(%d) agent kill cache", uid)
	return servicecode.SUCCESS
end

function _M.auth(args)
	local obj = assert(objmgr.get(args.uid))
	obj.fd = args.client
	obj.authed = true
	objmgr.addfd(obj)
	assert(obj == objmgr.get(args.client))
	return true
end

function _M.afk(fd)
	-- body
	log.info('agent fd(%d) afk', fd)
	local obj = objmgr.get(fd)
	return logout.logout(obj)
end
