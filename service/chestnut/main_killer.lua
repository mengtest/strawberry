local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"

skynet.start(function()
	skynet.send("CODWEB", "lua", "kill")
	-- skynet.exit()
	-- skynet.abort()
end)
