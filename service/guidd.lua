-- if client for this node has 
local skynet = require "skynet"
local snowflake = require "chestnut.snowflake"
local service = require "service"
local worker  = 1
-- local cross_worker = skynet.getenv("cross_worker")
local CMD = {}

service.init {
	init = function ()
		snowflake.init(worker)
	end,
	command = CMD
}