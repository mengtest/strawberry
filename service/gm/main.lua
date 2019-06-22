local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local cluster = require "skynet.cluster"

skynet.start(function()

	-- log
	-- debug
	-- local console = skynet.newservice("console")
	-- skynet.newservice("debug_console",8000)

	skynet.uniqueservice("db")
	skynet.uniqueservice("gm/simpleweb")

	local gm = skynet.getenv 'gm'
	local logind = skynet.getenv 'logind'
	local game1 = skynet.getenv 'game1'
	cluster.reload({
		gm = gm,
		logind = logind,
		game1 = game1
	})
	cluster.open 'gm'

	skynet.exit()
	
end)
