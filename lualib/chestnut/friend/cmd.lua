local skynet = require "skynet"
local mc = require "skynet.multicast"
local savedata = require "savedata"
local command = require "command"
local CMD = require "cmd"

-- function CMD:start()
-- 	-- body
-- 	savedata.init {}
-- 	return true
-- 	-- local channel = mc.new {
-- 	-- 	channel = channel_id,
-- 	-- 	dispatch = function (_, _, cmd, ...)
-- 	-- 		-- body
-- 	-- 		local f = assert(CMD[cmd])
-- 	-- 		local ok, result = pcall(f, self, ... )
-- 	-- 		if not ok then
-- 	-- 			log.error(result)
-- 	-- 		end
-- 	-- 	end
-- 	-- }
-- 	-- channel:subscribe()
-- 	-- return self:start()
-- end

-- function CMD:init_data()
-- 	return true
-- end

-- function CMD:sayhi()
-- 	return true
-- end

-- function CMD:save_data()
-- end

-- function CMD:close()
-- 	return true
-- end

-- function CMD:kill()
-- 	-- body
-- 	skynet.exit()
-- end

------------------------------------------
-- gameplay 协议
function CMD.add_friend_req(obj, args)
	return self:query(session)
end

return CMD
