local skynet = require "skynet"
local ball = require "ball"
local systemcontainer = require "systemcontainer"
local entity = require "room.components"
local basesystem = require "room.systems.base"
local tiny = require "tiny"
local assert = assert

local cls = class("context")

function cls:ctor(id, ... )
	-- body
	self.ball = ball()
	self.pool = Chestnut.EntitasPP.Pool.Create()
	self.joinsystem = Chestnut.Ball.JoinSystem.Create()
	self.mapsystem = Chestnut.Ball.MapSystem.Create()
	self.movesystem = Chestnut.Ball.MoveSystem.Create()
	self.indexsystem = Chestnut.Ball.IndexSystem.Create()
	
	self.pool:Test()

	-- self.pool:CreateSystemPtr(self.joinsystem)
	-- self.pool:CreateSystemPtr(self.mapsystem)
	-- self.pool:CreateSystemPtr(self.movesystem)
	-- self.pool:CreateSystemPtr(self.indexsystem)

	self.systemcontainer = systemcontainer.new(self.pool)

	self.systemcontainer:add(self.joinsystem)
	self.systemcontainer:add(self.mapsystem)
	self.systemcontainer:add(self.movesystem)
	self.systemcontainer:add(self.indexsystem)

	self.systemcontainer:setpool()

	self.tinyworld = tiny.world(basesystem)

	self.mode = nil
	self.max_number = 10
	return self
end

function cls:push_client(name, args, ... )
	-- body
	for _,v in pairs(self._playeres) do
		local agent = v:get_agent()
		skynet.send(agent, "lua", name, args)
	end
end

function cls:start(mode, ... )
	-- body
	self.mode = mode
	
	-- load map id
	self.systemcontainer:initialize()

	-- update
	skynet.fork(function ( ... )
		-- body
		skynet.sleep(100 / 5) -- 5fps
		self:fixedupdate()
	end)
	return true
end

function cls:close( ... )
	-- body
	for _,user in pairs(users) do
		gate.req.unregister(user.session)
	end
	return true
end

function cls:fixedupdate( ... )
	-- body
	self.tinyworld:update()
	self.systemcontainer:fixedexcute()
end

function cls:match(conf, ... )
	-- body

	basesystem:match(self.tinyworld, conf)

	return true
end

function cls:join(index, ... )
	-- body
	self.joinsystem:Join(index)
end

function cls:leave(index, ... )
	-- body
	self.joinsystem:Leave(index)
end


return cls