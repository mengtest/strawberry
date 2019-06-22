local skynet = require "skynet"
local objmgr = require "objmgr"
local servicecode = require "enum.servicecode"
local log = require "chestnut.skynet.log"

local _M = {}

function _M.logout(obj, ... )
    -- body
    assert(obj.authed)
	if obj.authed then
		-- log.info("uid(%d) systems begin-------------------------------------afk", obj.uid)
		-- local traceback = debug.traceback
		-- local ok, err = xpcall(self.systems.afk, traceback, self.systems)
		-- if not ok then
		-- 	log.error(err)
		-- end
		-- log.info("uid(%d) systems end-------------------------------------afk", self.uid)
		-- if self.channelSubscribed then
		-- 	self.channelSubscribed = false
		-- 	self.channel:unsubscribe()
        -- end
		local err = skynet.call(obj.gate, 'lua', 'logout', obj.uid, obj.subid)
		if err == servicecode.SUCCESS then
			log.info('uid(%d) agent afk', obj.uid)
		end
		return err
	else
		return servicecode.NOT_AUTHED
	end
end

return _M