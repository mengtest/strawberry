local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require("service")
local loader = require("sdataloader")

local CMD = {}

-- function CMD.start( ... )
-- 	-- body
-- 	-- 更新数据
-- 	local config = AppConfig.new()
-- 	if config:LoadFile() then
-- 		for k,v in pairs(config.config) do
-- 			builder.new(k, v)
-- 		end
-- 		return true
-- 	end
-- 	return false
-- end

-- function CMD.init_data()
-- 	return true
-- end

-- function CMD.close( ... )
-- 	-- body
-- 	return true
-- end

-- function CMD.kill( ... )
-- 	-- body
-- 	skynet.exit()
-- end

function CMD.reload( ... )
	-- body
end

service.init {
	init = function ()
		loader()
	end,
	command = CMD
}
