local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local service = require "service"

local services = {}

local CMD = {}

function CMD.start()
	-- body
	local ok = false
	log.info('start server ...')
	-- db
	skynet.uniqueservice("db")
	
	-- guidd
	
	-- config
	skynet.uniqueservice("chestnut/sdata_mgr")

	-- global service
	local sid_mgr = skynet.uniqueservice("chestnut/sid_mgr")
	ok = skynet.call(sid_mgr, "lua", "start")
	if not ok then
		log.error("call sid_mgr failture.")
		skynet.exit()
	end
	table.insert(services, sid_mgr)
	log.info("sid_mgr start success.")

	local room_mgr = skynet.uniqueservice("chestnut/room_mgr")
	skynet.call(room_mgr, "lua", "start")
	table.insert(services, room_mgr)
	log.info("room_mgr start success.")

	local radio_mgr = skynet.uniqueservice("chestnut/radio_mgr")
	skynet.call(radio_mgr, "lua", "start")
	table.insert(services, radio_mgr)
	log.info("radiocenter start success.")

	local chat_mgr = skynet.uniqueservice("chestnut/chat_mgr")
	skynet.call(chat_mgr, "lua", "start")
	table.insert(services, chat)
	log.info("chat_mgr start success.")

	local mail_mgr = skynet.uniqueservice("chestnut/mail_mgr")
	skynet.call(mail_mgr, "lua", "start")
	table.insert(services, mail_mgr)
	log.info("sysemaild start success.")

	local record_mgr = skynet.uniqueservice("chestnut/record_mgr")
	skynet.call(record_mgr, "lua", "start")
	table.insert(services, record_mgr)
	log.info("record_mgr start success.")

	local offagent_mgr = skynet.uniqueservice("chestnut/offagent_mgr")
	skynet.call(offagent_mgr, "lua", "start")
	table.insert(services, offagent_mgr)
	log.info("offagent start success.")

	local agent_mgr = skynet.uniqueservice("chestnut/agent_mgr")
	skynet.call(agent_mgr, "lua", "start")
	table.insert(services, agent_mgr)
	log.info("agent_mgr start success.")

	local activity_mgr = skynet.uniqueservice("chestnut/activity_mgr")
	skynet.call(activity_mgr, "lua", "start")
	table.insert(services, activity_mgr)
	log.info("activity_mgr start success.")

	local friend_mgr = skynet.uniqueservice("chestnut/friend_mgr")
	skynet.call(friend_mgr, "lua", "start")
	table.insert(services, friend_mgr)
	log.info("friend_mgr start success.")

	local zset_mgr = skynet.uniqueservice("chestnut/zset_mgr")
	skynet.call(zset_mgr, "lua", "start")
	table.insert(services, zset_mgr)
	log.info("friend_mgr start success.")
	
	local loginType = skynet.getenv 'login_type'
	if loginType == 'so' then
		local verify = skynet.uniqueservice("logind/logindverify")
		skynet.call(verify, "lua", "start")

		local logind = skynet.getenv("logind") or "0.0.0.0:3002"
		local addr = skynet.newservice("logind/logind", logind)
		skynet.name(".LOGIND", addr)

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

	-- skynet.error(loginType)
	return true
end

function CMD.init_data()
	-- body
	for _,v in pairs(services) do
		skynet.call(v, "lua", "init_data")
		log.info("init data success.")
	end
	log.info("init_data over.")
	return true
end

function CMD.sayhi()
	-- body
	for _,v in pairs(services) do
		skynet.call(v, "lua", "sayhi")
	end
	log.info("sayhi over.")
	return true
end

function CMD.kill()
	-- body
	for _,v in pairs(services) do
		skynet.call(v, "lua", "close")
	end
	log.info('kill services')
	-- skynet.exit()
	-- skynet.abort()
end

service.init {
	name = ".LIFE_MGR",
	command = CMD
}
