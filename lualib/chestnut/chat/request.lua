local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.chat.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.say(self, args)
	local obj = self.obj
	return context.say(obj, args)
end

return REQUEST
