local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.bag.context"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.fetch_items(fd, args)
	context.fetch_items(fd, args)
end

return REQUEST
