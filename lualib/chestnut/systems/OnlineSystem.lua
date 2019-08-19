local skynet = require "skynet"
local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local client = require "client"
local luaTableDump = require "luaTableDump"
local table_insert = table.insert

local _M = {}

function _M:login()
	-- body
	local uid = self.context.uid
	local subid = self.context.subid
	local ok = skynet.call(".ONLINE_MGR", "lua", "login", uid, subid, skynet.self())
end

function _M:logout()
	-- body
	local uid = self.context.uid
	local subid = self.context.subid
	skynet.call(".ONLINE_MGR", "lua", "logout", uid, subid)
end

function _M:authed(args)
	-- body
	local fd = assert(args.client)

	local uid = self.context.uid
	local subid = self.context.subid

	skynet.call(".ONLINE_MGR", "lua", "authed", uid, subid, fd)
end

function _M:afk( ... )
	-- body
	local uid = self.context.uid
	local subid = self.context.subid

	skynet.call(".ONLINE_MGR", "lua", "afk", uid, subid)
end

return _M
