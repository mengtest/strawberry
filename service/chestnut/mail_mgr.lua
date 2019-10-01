local service = require "service"
local CMD = require "chestnut.mail_mgr.cmd"
require "chestnut.mail_mgr.context"
service.init {
	name = ".MAIL_MGR",
	command = CMD
}
