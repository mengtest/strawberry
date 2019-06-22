local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"

skynet.start(function()

	skynet.uniqueservice("protoloader")

	-- local console = skynet.newservice("console")
	-- skynet.newservice("debug_console",8000)

	local codweb = skynet.uniqueservice("codweb")
	local ok = skynet.call(codweb, "lua", "start")
	if not ok then
		log.error("start codweb faile, kill server.")
		assert(skynet.call(codweb, "lua", "kill"))
		log.error("start codweb faile, kill main.")
		skynet.abort()
	else
		skynet.call(codweb, "lua", "init_data")
		skynet.call(codweb, "lua", "sayhi")
		log.info("host successful --------------------------------------------")

		-- MOCK
		-- local agent_robot = skynet.uniqueservice("agent_robot/agent")
		-- skynet.call(agent_robot, "lua", "login")
		-- skynet.call(agent_robot, "lua", 'auth')
		skynet.exit()
	end
end)
