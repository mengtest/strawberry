local client = require "client"
local CMD = require("chestnut.agent.cmd")
local REQUEST = client.request()

local _M = {}

function _M:on_data_init(dbData)
	-- body
	assert(dbData ~= nil)
	if dbData.db_user_achievements ~= nil then
		
	end
	return true
end

function _M:on_data_save(dbData, ... )
	-- body
	assert(dbData ~= nil)

	return true
end

function _M:on_enter()
	client.push(self, '')
end


function REQUEST:mm(msg)
end

function CMD:aa(msg)
	local obj = objmgr.get(uid)
end

return _M