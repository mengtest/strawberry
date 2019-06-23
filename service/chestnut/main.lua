local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local cluster = require "skynet.cluster"
local lifemgr = require 'lifemgr'

skynet.start(function()

	-- open cluster
	local gm = skynet.getenv 'cluster_gm'
	local logind = skynet.getenv 'cluster_logind'
	local game1 = skynet.getenv 'cluster_game1'
	cluster.reload({
		gm = gm,
		logind = logind,
		game1 = game1
	})
	cluster.open 'game1'

	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8001)

	skynet.uniqueservice("protoloader")
	-- config
	skynet.uniqueservice("chestnut/sdata_mgr")
	skynet.uniqueservice("db")
	skynet.uniqueservice("chestnut/sid_mgr")

	lifemgr.uniqueservice("chestnut/radio_mgr")
	lifemgr.uniqueservice("chestnut/chat_mgr")
	lifemgr.uniqueservice("chestnut/mail_mgr")
	lifemgr.uniqueservice("chestnut/record_mgr")
	lifemgr.uniqueservice("chestnut/offagent_mgr")
	lifemgr.uniqueservice("chestnut/activity_mgr")
	lifemgr.uniqueservice("chestnut/friend_mgr")
	lifemgr.uniqueservice("chestnut/zset_mgr")
	lifemgr.uniqueservice('chestnut/room_mgr')
	lifemgr.uniqueservice("chestnut/agent_mgr")

	local loginType = skynet.getenv 'login_type'
	if loginType == 'so' then
		-- local verify = skynet.uniqueservice("logind/logindverify")
		-- skynet.call(verify, "lua", "start")

		-- local logind = skynet.getenv("logind") or "0.0.0.0:3002"
		-- local addr = skynet.newservice("logind/logind", logind)
		-- skynet.name(".LOGIND", addr)

		local gated = skynet.getenv("gated") or "0.0.0.0:3301"
		local address, port = string.match(gated, "([%d.]+)%:(%d+)")
		local gated_name = skynet.getenv("gated_name") or "sample"
		local max_client = skynet.getenv("maxclient") or 1024
		local gate = skynet.uniqueservice("chestnut/gated")
		skynet.call(gate, "lua", "open", {
			address = address or "0.0.0.0",
			port = port,
			maxclient = tonumber(max_client),
			servername = gated_name,
			--nodelay = true,
		})

		local udpgated = skynet.getenv("udpgated")
		if udpgated then
			-- local address, port = string.match(udpgated, "([%d.]+)%:(%d+)")
			-- local gated_name = skynet.getenv("gated_name") or "sample"
			-- local max_client = skynet.getenv("maxclient") or 1024
			-- local udpgate = skynet.uniqueservice("rudpserver_mgr")
			-- skynet.call(udpgate, "lua", "start")
		end
	else
		skynet.uniqueservice("wslogind")

		local wsgated = skynet.uniqueservice('wsgated')
		skynet.call(wsgated, "lua", "start")
		log.info("wsgated start success.")
	end

	-- MOCK
	-- local agent_robot = skynet.uniqueservice("agent_robot/agent")
	-- skynet.call(agent_robot, "lua", "login")
	-- skynet.call(agent_robot, "lua", 'auth')
		
	log.info("host successful --------------------------------------------")
	skynet.exit()
end)
