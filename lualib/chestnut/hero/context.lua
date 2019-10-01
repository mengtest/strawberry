local skynet = require "skynet"
local sd = require "skynet.sharetable"
local log = require "chestnut.skynet.log"
local objmgr = require "objmgr"
local client = require "client"
local table_dump = require "luaTableDump"
local servicecode = require "enum.servicecode"
local assert = assert
local _M = {}
local info_cfg

skynet.init(
	function()
		info_cfg = sd.query("InfoConfig")
	end
)

local function init_hero(obj)
end

function _M.init(id, ...)
	-- body
	-- self.ball = ball()
	-- self.pool = Chestnut.EntitasPP.Pool.Create()
	-- self.joinsystem = Chestnut.Ball.JoinSystem.Create()
	-- self.mapsystem = Chestnut.Ball.MapSystem.Create()
	-- self.movesystem = Chestnut.Ball.MoveSystem.Create()
	-- self.indexsystem = Chestnut.Ball.IndexSystem.Create()

	-- self.pool:Test()

	-- self.pool:CreateSystemPtr(self.joinsystem)
	-- self.pool:CreateSystemPtr(self.mapsystem)
	-- self.pool:CreateSystemPtr(self.movesystem)
	-- self.pool:CreateSystemPtr(self.indexsystem)

	-- self.systemcontainer = systemcontainer.new(self.pool)

	-- self.systemcontainer:add(self.joinsystem)
	-- self.systemcontainer:add(self.mapsystem)
	-- self.systemcontainer:add(self.movesystem)
	-- self.systemcontainer:add(self.indexsystem)

	-- self.systemcontainer:setpool()

	-- self.tinyworld = tiny.world(basesystem)
	self.id = id
	self.mode = nil
	self.max_number = 10
	return self
end

function _M.on_data_init(self, db_data)
	self.mod_hero = {}
	self.mod_hero.heros = {}
	for k, v in pairs(db_data.db_user_heros) do
		local hero = {}
		hero.hero_id = v.hero_id
		hero.level = v.level
		hero.create_at = v.create_at
		hero.update_at = v.update_at
		self.mod_hero.heros[hero.hero_id] = hero
	end
end

function _M.on_data_save(self, db_data)
	db_data.db_user_heros = {}
	for _, v in pairs(self.mod_hero.heros) do
		local hero = {}
		hero.uid = self.uid
		hero.hero_id = v.hero_id
		hero.level = v.level
		hero.create_at = v.create_at
		hero.update_at = os.time()
		table.insert(db_data.db_user_heros, hero)
	end
end

function _M.on_enter(self)
	client.push(self, "player_heros", {list = {{id = 111, level = 1}}})
end

------------------------------------------
-- 逻辑
function _M.fetch_heros(fd, args)
	local obj = objmgr.get_by_fd(fd)
	return {errorcode = 0}
end

function _M.fetch_hero(fd, args)
	local obj = objmgr.get_by_fd(fd)
	return {errorcode = 0}
end

return _M
