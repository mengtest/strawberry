local ds = require "skynet.datasheet"
local log = require "chestnut.skynet.log"

local CLS_NAME = "func_open"

local cls = {}

function cls:on_data_init(dbData)
	-- body
	assert(dbData ~= nil)
	assert(dbData.db_user_funcopens ~= nil and #dbData.db_user_funcopens > 0)

	local funcs = {}
	for _,db_item in pairs(dbData.db_user_funcopens) do
		local item = {}
		item.id = assert(db_item.id)
		item.open = assert(db_item.open)
		item.createAt = assert(db_item.create_at)
		item.updateAt = assert(db_item.update_at)
		funcs[tonumber(item.id)] = item
	end
	self.dbFuncopen = funcs
end

function cls:on_data_save(dbData, ... )
	-- body
	assert(dbData ~= nil)

	-- save user
	dbData.db_user_funcopens = {}
	for _,item in pairs(self.dbFuncopen) do
		-- print(k, item)
		local db_item = {}
		db_item.uid = assert(self.agentContext.uid)
		db_item.id  = assert(item.id)
		db_item.open = assert(item.open)
		db_item.create_at = assert(item.createAt)
		db_item.update_at = os.time()
		table.insert(dbData.db_user_funcopens, db_item)
	end
	return true
end

function cls:enter( ... )
	-- body
	cls.on_level_open(self)
end

function cls:afk( ... )
	-- body
end


function cls:on_level_open()
	-- body
	local uid = self.agentContext.uid
	local userSystem = self.agentSystems.user
	local funcopens = ds.query('funcopen')
	for _,v in pairs(funcopens) do
		if v.opentype == 1 then
			local id = assert(v.id)
			local func = self.dbFuncopen[id]
			if func.open == 0 then
				if userSystem.dbUser.level >= v.level then
					func.open = 1
					self:on_func_open(id)
				end
			end
		end
	end
end

function cls:on_func_open(id)
	-- body
	if id == 1 then
		self.agentSystems.package:on_func_open()
	elseif id == 2 then
		self.agentSystems.room:on_func_open()
	end
end

function cls:is_open(id)
	-- body
	assert(id >= 0)
	local uid = self.agentContext.uid	
	local func = self.dbFuncopen[id]
	if func and (func.open == 1) then
		return true
	else
		return false
	end
end

return cls