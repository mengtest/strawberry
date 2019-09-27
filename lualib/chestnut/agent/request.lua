local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.agent.context"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.handshake(fd)
	return context.handshake(fd)
end

function REQUEST.enter(fd)
	return context.enter(fd)
end

function REQUEST.logout(fd)
	return context.logout_req(fd)
end

------------------------------------------
-- 系统模块
function REQUEST.modify_name(fd, args)
	return context.modify_name(fd, args)
end

function REQUEST.rank_power(fd, args)
	return context.rank_power(fd, args)
end

function REQUEST.fetch_store_items(fd, args)
	return context.fetch_store_items(fd, args)
end

function REQUEST.fetch_store_item(fd, args)
	return context.fetch_store_item(fd, args)
end

function REQUEST.buy_store_item(fd, args)
	return context.buy_store_item(fd, args)
end

return REQUEST
