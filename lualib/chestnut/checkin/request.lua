local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.checkin.context"
local REQUEST = require "request"
local pcall = pcall
local assert = assert
local traceback = debug.traceback

function REQUEST.fetch_checkins(fd, args)
	return context.fetch_checkins(fd, args)
end

return REQUEST
