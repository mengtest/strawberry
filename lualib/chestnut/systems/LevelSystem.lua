-- local log = require "chestnut.skynet.log"
local ds = require "skynet.datasheet"

local cls = {}

function cls:on_data_init(dbData)
	-- body
	assert(self)
end

function cls:on_data_save(dbData, ... )
	-- body
	assert(self)
end

function cls:add_exp(exp)
	-- body
	assert(self)
	assert(exp > 0)

	local user = self.agentSystems.user
	for i=1,exp do
		user.dbUser.exp = user.dbUser.exp + 1
		-- if user.dbUser.exp >
	end
end

return cls