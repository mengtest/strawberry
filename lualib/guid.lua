local skynet = require "skynet"
local snowflake = require "chestnut.snowflake"
local address

function guid( ... )
	-- body
	if not address then
		address = skynet.uniqueservice("guidd")
	end
	return snowflake.next_id()
end

return guid