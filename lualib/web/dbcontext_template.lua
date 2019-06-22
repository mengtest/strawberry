local s = [[
local dbcontext = require "dbcontext"
local cls = class("%s", dbcontext)

function cls:ctor(env, rdb, wdb, ... )
	-- body
	assert(env and rdb and wdb)
	cls.super.ctor(self, env, rdb, wdb)
	self._dbset = {}
	return self
end

%s

return cls
]]

return s