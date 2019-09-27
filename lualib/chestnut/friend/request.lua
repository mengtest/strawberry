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

function REQUEST.fetch_friends(fd, args)
	local obj = self.obj
	return context.fetch_friends(fd, args)
end

function REQUEST.fetch_friend(self, args)
	local obj = self.obj
	return context.fetch_friend(obj, args)
end

function REQUEST.rm_friend(self, args)
	local obj = self.obj
	return context.rm_friend(self, args)
end

function REQUEST.fetch_friend_reqs(self, args)
	local obj = self.obj
	return context.fetch_friend_reqs(self, args)
end

function REQUEST.acc_friend_req(self, args)
	local obj = self.obj
	return context.acc_friend_req(obj, args)
end

function REQUEST.rej_friend_req(self, args)
	local obj = self.obj
	return context.rej_friend_req(obj, args)
end

function REQUEST.acc_friend_req_all(self, args)
	local obj = self.obj
	return context.acc_friend_req_all(obj, args)
end

function REQUEST.rej_friend_req_all(self, args)
	local obj = self.obj
	return context.rej_friend_req_all(obj, args)
end

return REQUEST
