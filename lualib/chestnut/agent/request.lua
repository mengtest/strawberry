local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local AgentSystems = require "chestnut.agent.systems"
local servicecode = require "enum.servicecode"
local client = require "client"
local table_dump = require "luaTableDump"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.handshake(self)
	-- body
	-- skynet.error('handshake')
	-- log.info("test handshake")
	local obj = self.obj
	client.push(obj, "handshake")
	local res = {}
	res.errorcode = 0
	return res
end

function REQUEST.enter(self)
	local ok, err = xpcall(AgentSystems.on_enter, traceback, self.obj)
	if not ok then
		log.error(err)
		return {errorcode = 1}
	end
	return {errorcode = 0}
end

function REQUEST.logout(self)
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
function REQUEST.modify_name(self, args)
	local obj = self.obj
	obj.mod_user.nickname = args.nickname
	log.info("uid(%d) REQUEST = [modify_name], nickname = [%s]", obj.uid, obj.mod_user.nickname)
	client.push(obj, "new_name", {nickname = obj.mod_user.nickname})
	local res = {}
	res.errorcode = 1
	return res
end

function REQUEST.rank_power(self, args)
end

return REQUEST
