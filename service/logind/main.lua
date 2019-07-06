local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local server = require 'server'

skynet.start(function()

	-- open cluster
	server.host.open_logind()

	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	skynet.uniqueservice("db")

	-- login
	local loginType = skynet.getenv 'login_type'
	if loginType == 'so' then
		skynet.uniqueservice("logind/logindverify")
		
		local logind = skynet.getenv("logind") or "0.0.0.0:3002"
		local addr = skynet.newservice("logind/logind", logind)
		skynet.name(".LOGIND", addr)
		server.host.register_service('.LOGIND', addr)
	else 
		skynet.uniqueservice("wslogind")
		local wsgated = skynet.uniqueservice('wsgated')
		skynet.call(wsgated, "lua", "start")
		log.info("wsgated start success.")
	end

	skynet.exit()
end)
