local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local cluster = require "skynet.cluster"

skynet.start(function()

	-- local console = skynet.newservice("console")
	-- skynet.newservice("debug_console",8000)

	skynet.uniqueservice("db")

	-- login
	local loginType = skynet.getenv 'login_type'
	if loginType == 'so' then
		local verify = skynet.uniqueservice("logind/logindverify")
		skynet.call(verify, "lua", "start")

		local logind = skynet.getenv("logind") or "0.0.0.0:3002"
		local addr = skynet.newservice("logind/logind", logind)
		skynet.name(".LOGIND", addr)

	else 
		skynet.uniqueservice("wslogind")
		local wsgated = skynet.uniqueservice('wsgated')
		skynet.call(wsgated, "lua", "start")
		log.info("wsgated start success.")
	end

	local gm = skynet.getenv 'gm'
	local logind = skynet.getenv 'logind'
	local game1 = skynet.getenv 'game1'
	cluster.reload({
		gm = gm,
		logind = logind,
		game1 = game1
	})
	cluster.open 'logind'

	skynet.exit()
end)
