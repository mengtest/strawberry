local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local AgentSystems = require "chestnut.agent.systems"
local servicecode = require "enum.servicecode"
local CMD = require "chestnut.agent.cmd"
local request = require "chestnut.agent.request"
local response = require "chestnut.agent.response"
local logout = require "chestnut.agent.logout"
local objmgr = require "objmgr"
local client = require "client"
local dbc = require "db.db"
local stp = require "StackTracePlus"
local traceback = stp.stacktrace
local _M = {}
local assert = assert
local _reload = false

local function init_data(obj)
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

skynet.init(
	function()
	end
)

function _M.start()
end

function _M.init_data()
end

function _M.sayhi(reload)
	-- 重连的时候，auth函数用此判断
	_reload = reload
	return true
end

function _M.close()
	return true
end

function _M.kill()
end

function _M.save_data()
	objmgr.foreach(
		function(obj)
			if obj.authed then
				local data = {}
				local ok, err = xpcall(AgentSystems.on_data_save, traceback, obj, data)
				if ok then
					if table.length(data) > 0 then
						dbc.write_user(data)
					else
						log.error("uid(%d) not data", obj.uid)
					end
				else
					log.error(err)
				end
			end
		end
	)
end

function _M.login(gate, uid, subid, secret)
	log.info("agent login")
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

function _M.logout_req(fd)
	local obj = objmgr.get_by_fd(fd)
	local res = {}
	if logout.logout(obj) == servicecode.SUCCESS then
		res.errorcode = 0
	else
		res.errorcode = 1
	end
	return res
end

-- call by agent mgr
function _M.kill_cache(uid)
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
	assert(obj == objmgr.get_by_fd(args.client))
	return true
end

function _M.afk(fd)
	log.info("agent fd(%d) afk", fd)
	local obj = objmgr.get_by_fd(fd)
	return logout.logout(obj)
end

function _M.handshake(fd)
	local obj = objmgr.get_by_fd(fd)
	client.push(obj, "handshake")
	local res = {}
	res.errorcode = 0
	return res
end

function _M.enter(fd)
	local obj = objmgr.get_by_fd(fd)
	local ok, err = xpcall(AgentSystems.on_enter, traceback, obj)
	if not ok then
		log.error(err)
		return {errorcode = 1}
	end
	return {errorcode = 0}
end

function _M.modify_name(fd, args)
	local obj = objmgr.get_by_fd(fd)
	obj.mod_user.nickname = args.nickname
	log.info("uid(%d) REQUEST = [modify_name], nickname = [%s]", obj.uid, obj.mod_user.nickname)
	client.push(obj, "new_name", {nickname = obj.mod_user.nickname})
	local res = {}
	res.errorcode = 1
	return res
end

return _M
