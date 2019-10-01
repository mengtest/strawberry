local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.chat.context"
local REQUEST = require "request"
local pcall = pcall
local assert = assert
local traceback = debug.traceback

function REQUEST.say(self, args)
	local obj = self.obj
	return context.say(obj, args)
end

return REQUEST
