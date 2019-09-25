local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local time_utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local context = require "chestnut.mail.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.fetchinbox(self, args)
	return context.fetch(self.obj, args)
end

function REQUEST.syncsysmail(self, args)
	return context.sync(self.obj, args)
end

function REQUEST.viewedsysmail(self, args)
	return context.viewed(self.obj, args)
end

return REQUEST
