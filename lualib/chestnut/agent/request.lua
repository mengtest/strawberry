local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local utils = require "common.utils"
local logout = require "chestnut.agent.logout"
local context = require "chestnut.agent.context"
local client = require "client"
local table_dump = require "luaTableDump"
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

function REQUEST.rank_power(self, args)
end

function REQUEST.fetch_store_items(self, args)
end

function REQUEST.fetch_store_item(self, args)
end

function REQUEST.buy_store_item(self, args)
end

return REQUEST
