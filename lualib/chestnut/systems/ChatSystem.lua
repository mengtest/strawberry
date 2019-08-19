local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local zset = require "chestnut.zset"
local query = require "chestnut.query"
local sysmaild = require "sysmaild"
local client = require "client"
local CH = client.request()
local _M = {}

skynet.init(function ()
	-- body
end)

function _M:on_data_init(dbData)
	-- body
	assert(dbData ~= nil)
	assert(dbData.db_users ~= nil)
	assert(#dbData.db_users == 1)

	return true
end

function _M:on_data_save(dbData)
	-- body
	assert(dbData ~= nil)

	return true
end

return _M