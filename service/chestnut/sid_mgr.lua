local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require("service")

local internal_id = 1

local cmd = {}

function cmd.enter( ... )
	-- body
	internal_id = internal_id + 1
	return internal_id
end

service.init {
	name = '.SID_MGR',
	command = cmd
}
