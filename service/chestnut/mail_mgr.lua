local service = require "service"
local CMD = require "chestnut.mail_mgr.cmd"
service.init {
	command = CMD
}
