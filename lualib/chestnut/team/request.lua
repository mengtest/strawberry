local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.team.context"
local servicecode = require "enum.servicecode"
local REQUEST = require "request"
local pcall = pcall
local assert = assert
local traceback = debug.traceback

function REQUEST.fetch_taskdailys(self, args)
	local obj = self.obj
	return context.fetch(obj, args)
end

return REQUEST
