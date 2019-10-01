local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.record.context"
local REQUEST = require "request"
local pcall = pcall
local assert = assert
local traceback = debug.traceback

function REQUEST.fetch_records(fd, args)
	return context.fetch_records(fd, args)
end

return REQUEST
