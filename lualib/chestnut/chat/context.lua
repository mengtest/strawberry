local skynet = require "skynet"
local sd = require "skynet.sharetable"
local savedata = require "savedata"
local snowflake = require "chestnut.snowflake"
local client = require "client"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"
local _M = {}

skynet.init(
	function()
	end
)

function _M.on_data_init(self, dbData)
	assert(dbData ~= nil)
	assert(dbData.db_users ~= nil)
	assert(#dbData.db_users == 1)

	return true
end

function _M.on_data_save(self, dbData)
	assert(dbData ~= nil)

	return true
end

function _M:on_enter()
end

return _M
