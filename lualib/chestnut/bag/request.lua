local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.bag.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST:fetchinbox(args)
	-- body
	local M = self.modules.inbox
	return M:fetch(args)
end

function REQUEST:syncsysmail(args)
	-- body
	return self._sysinbox:sync(args)
end

function REQUEST:viewedsysmail(args, ...)
	-- body
	local entity = self:get_entity()
	local sysinbox = entity:get_component("sysinbox")
	return sysinbox:viewed(args)
end

return REQUEST
