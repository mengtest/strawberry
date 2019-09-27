local skynet = require "skynet"
local sd = require "skynet.sharetable"
local log = require "chestnut.skynet.log"
local client = require "client"
local table_dump = require "luaTableDump"
local user = require "chestnut.systems.user"
local table_insert = table.insert
local _M = {}
local funcopen_config

skynet.init(
	function()
		funcopen_config = sd.query("funcopenConfig")
		log.info(table_dump(funcopen_config))
	end
)

function _M.on_data_init(self, db_data)
	self.mod_funcopen = {}
	if #db_data.db_user_funcopens <= 0 then
		local funcs = {}
		for k, cfg in pairs(funcopen_config) do
			local item = {}
			item.id = tonumber(cfg.id)
			item.open = 0
			item.createAt = os.time()
			item.updateAt = os.time()
			funcs[tonumber(item.id)] = item
		end
		self.mod_funcopen.funcs = funcs
	else
		local funcs = {}
		for _, db_item in pairs(db_data.db_user_funcopens) do
			local item = {}
			item.id = assert(db_item.id)
			item.open = assert(db_item.open)
			item.createAt = assert(db_item.create_at)
			item.updateAt = assert(db_item.update_at)
			funcs[tonumber(item.id)] = item
		end
		self.mod_funcopen.funcs = funcs
	end
end

function _M.on_data_save(self, db_data)
	db_data.db_user_funcopens = {}
	for _, item in pairs(self.mod_funcopen.funcs) do
		local db_item = {}
		db_item.uid = assert(self.uid)
		db_item.id = assert(item.id)
		db_item.open = assert(item.open)
		db_item.create_at = assert(item.createAt)
		db_item.update_at = os.time()
		table_insert(db_data.db_user_funcopens, db_item)
	end
end

function _M.on_enter(self)
	local pack = {}
	pack.list = {}
	local data = self.mod_funcopen.funcs
	for k, v in pairs(data) do
		local item = {}
		item.id = v.id
		item.open = v.open
		table.insert(pack.list, item)
	end
	client.push(self, "player_funcs", pack)
end

function _M.on_exit(self)
end

function _M.on_level_open(self)
	local uid = self.uid
	for _, v in pairs(funcopen_config) do
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

function _M.on_func_open(self, id)
	if id == 1 then
		self.agentSystems.package:on_func_open()
	elseif id == 2 then
		self.agentSystems.room:on_func_open()
	end
end

function _M.is_open(self, id)
	assert(id >= 0)
	local uid = self.agentContext.uid
	local func = self.dbFuncopen[id]
	if func and (func.open == 1) then
		return true
	else
		return false
	end
end

return _M
