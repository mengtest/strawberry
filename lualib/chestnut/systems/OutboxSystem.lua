local skynet = require "skynet"
local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"
local client = require "client"
local CH = client.request()
local _M = {}

function _M:on_data_init(dbData)
	-- body
	assert(dbData ~= nil)
	assert(dbData.db_users ~= nil)
	assert(#dbData.db_users == 1)

	return true
end

function _M:on_data_save(dbData, ... )
	-- body
	assert(dbData ~= nil)

	return true
end

return _M