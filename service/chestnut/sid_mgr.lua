local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require("service")

local internal_id = 1

local cmd = {}

function cmd.start( ... )
	-- body
	return true
end

function cmd.init_data()
	return true
end

function cmd.sayhi()
	return true
end

function cmd.close( ... )
	-- body
	return true
end

function cmd.enter( ... )
	-- body
	internal_id = internal_id + 1
	return internal_id
end

service.init {
	name = '.SID_MGR',
	command = cmd
}
