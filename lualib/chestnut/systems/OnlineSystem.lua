local skynet = require "skynet"

local cls = class("online")

function cls:ctor(context, ... )
	-- body
	cls.super.ctor(self, context)

	return self
end

function cls:login()
	-- body
	local uid = self.context.uid
	local subid = self.context.subid
	local ok = skynet.call(".ONLINE_MGR", "lua", "login", uid, subid, skynet.self())
end

function cls:logout()
	-- body
	local uid = self.context.uid
	local subid = self.context.subid
	skynet.call(".ONLINE_MGR", "lua", "logout", uid, subid)
end

function cls:authed(args)
	-- body
	local fd = assert(args.client)

	local uid = self.context.uid
	local subid = self.context.subid

	skynet.call(".ONLINE_MGR", "lua", "authed", uid, subid, fd)
end

function cls:afk( ... )
	-- body
	local uid = self.context.uid
	local subid = self.context.subid

	skynet.call(".ONLINE_MGR", "lua", "afk", uid, subid)
end

return cls
