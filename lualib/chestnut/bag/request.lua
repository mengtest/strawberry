local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.bag.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.fetchinbox(self, args)
	local obj = self.obj
	context.package_info(obj, args)
end

function REQUEST.syncsysmail(self, args)
	local obj = self.obj
	return context.sync(obj, args)
end

function REQUEST.viewedsysmail(self, args)
	local entity = self:get_entity()
	local sysinbox = entity:get_component("sysinbox")
	return sysinbox:viewed(args)
end

return REQUEST
