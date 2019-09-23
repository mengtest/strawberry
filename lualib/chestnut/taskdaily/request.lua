local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local time_utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local context = require "chestnut.taskdaily.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST:taskdaily_fetch(args)
	local obj = self.obj
	return context.fetch(obj, args)
end

function REQUEST:syncsysmail(args)
	return context.sync(self, args)
end

function REQUEST:viewedsysmail(args)
	return context.viewed(self, args)
end

return REQUEST
