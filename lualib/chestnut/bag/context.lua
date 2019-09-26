local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local PackageType = require "enum.PackageType"
local sd = require "skynet.sharetable"
local objmgr = require "objmgr"
local _M = {}

skynet.init(
	function()
	end
)

local function push_items(obj)
end

function _M._increase(self, pt, id, num)
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	local package = assert(entity.package.packages[pt])
	if not package[id] then
		package[id] = {id = id, num = 0, createAt = os.time(), updateAt = os.time()}
	end
	package[id].num = package[id].num + num
	-- 增加道具
	local item = {id = id, num = num}
	self.agentContext:send_request("add_item", {i = item})
	return true
end

function _M._decrease(self, pt, id, num)
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	local package = assert(entity.package.packages[pt])
	if not package[id] then
		package[id] = {id = id, num = 0, createAt = os.time(), updateAt = os.time()}
	end
	local item = package[id]
	if item.num >= num then
		item.num = item.num - num
		local item = {id = id, num = num}
		self.agentContext:send_request("sub_item", {i = item})
	else
		log.error("not enought item, num is %d, need %d", item.num, num)
		return false
	end
	return true
end

function _M.on_data_init(self, dbData)
	if not dbData or not dbData.db_user_items then
		log.error("bag is nil")
		return
	end
	local set = dbData.db_user_items
	local package = {}
	for _, db_item in pairs(set) do
		local item = {}
		item.id = assert(db_item.id)
		item.num = assert(db_item.num)
		item.createAt = assert(db_item.create_at)
		item.updateAt = assert(db_item.update_at)
		package[tonumber(item.id)] = item
	end
	self.mod_bag = {bags = {}}
	self.mod_bag.bags[PackageType.COMMON] = package
end

function _M.on_data_save(self, dbData)
	dbData.db_user_items = {}
	local set = self.mod_bag.bags[PackageType.COMMON]
	local package = {}
	for _, db_item in pairs(set) do
		local item = {}
		item.uid = self.uid
		item.id = assert(db_item.id)
		item.num = assert(db_item.num)
		item.create_at = assert(db_item.createAt)
		item.update_at = assert(db_item.updateAt)
		table.insert(package, item)
	end
	dbData.db_user_items = package
end

function _M.on_enter(self)
	push_items(self)
end

function _M.on_exit(self)
end

function _M.on_func_open(self)
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	entity.package.packages = {}
	entity.package.packages[PackageType.COMMON] = {}
	entity.package.packages[PackageType.COMMON][1] = {id = 1, num = 113, createAt = os.time(), updateAt = os.time()} -- 砖石
	entity.package.packages[PackageType.COMMON][2] = {id = 2, num = 113, createAt = os.time(), updateAt = os.time()} -- 金币
	entity.package.packages[PackageType.COMMON][3] = {id = 3, num = 1, createAt = os.time(), updateAt = os.time()} -- 经验
	entity.package.packages[PackageType.COMMON][4] = {id = 4, num = 100, createAt = os.time(), updateAt = os.time()} -- 门票
end

function _M.check_consume(self, id, value)
	local uid = self.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	local itemConfig = ds.query("item")[string.format("%d", id)]
	local package = entity.package.packages[itemConfig.type]
	assert(package)
	local item = package[id]
	if item.num < value then
		return false
	end
	return true
end

function _M.consume(self, id, value)
	if not self:check_consume(id, value) then
		return false
	end
	local itemConfig = ds.query("item")[string.format("%d", id)]
	return self:_decrease(itemConfig.type, id, value)
end

function _M.rcard_num(self)
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	local package = entity.package.packages[PackageType.COMMON]
	assert(package)
	local item = package[4]
	if not item then
		item = {id = 4, num = 0}
		package[4] = item
	end
	return item.num
end

function _M.package_info(self)
	local uid = self.agentContext.uid
	local index = self.context:get_entity_index(UserComponent)
	local entity = index:get_entity(uid)
	local package = entity.package.packages[PackageType.COMMON]
	assert(package)
	local all = {}
	for _, v in pairs(package) do
		local item = {id = v.id, num = v.num}
		table.insert(all, item)
	end
	local res = {
		errorcode = 0,
		all = all
	}
	return res
end

return _M
