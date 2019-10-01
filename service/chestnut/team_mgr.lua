local service = require "service"
local CMD = require "chestnut.team_mgr.cmd"

service.init {
	name = ".TEAM_MGR",
	command = CMD
}
