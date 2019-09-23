local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local logout = require "chestnut.agent.logout"
local context = require "chestnut.chat.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST:say(args)
	local obj = self.obj
	return {}
end

return REQUEST
