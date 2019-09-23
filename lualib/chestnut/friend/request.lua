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

function REQUEST:fetch_friends(args)
	local obj = self.obj
	return context.fetch(self, args)
end

function REQUEST:rm_friend(args)
	local obj = self.obj
	return context.sync(self, args)
end

function REQUEST:fetch_friend_reqs(args)
	local obj = self.obj
end

function REQUEST:acc_friend_req(args)
end

function REQUEST:rej_friend_req(args)
end

function REQUEST:acc_friend_req_all(args)
end

function REQUEST:rej_friend_req_all(args)
end

return REQUEST
