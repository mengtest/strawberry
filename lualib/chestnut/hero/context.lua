local skynet = require "skynet"
local ds = require "skynet.sharetable"
local log = require "chestnut.skynet.log"
local request = require "chestnut.hero.request"
local response = require "chestnut.hero.response"
local objmgr = require "objmgr"
local client = require "client"
local table_dump = require "luaTableDump"
local assert = assert
local _M = {}
local hero_cfg

skynet.init(
	function()
		hero_cfg = ds.query("heroConfig")
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
-- 服务协议
function _M.start(self, mode, ...)
	-- body
	self.mode = mode

	-- load map id
	-- self.systemcontainer:initialize()

	-- update
	-- skynet.fork(function ( ... )
	-- 	-- body
	-- 	skynet.sleep(100 / 5) -- 5fps
	-- 	self:fixedupdate()
	-- end)
	return true
end

function _M:close(...)
	-- body
	for _, user in pairs(users) do
		gate.req.unregister(user.session)
	end
	return true
end

------------------------------------------
-- 房间协议
function _M.create()
end

function _M.join(uid, agent, name, sex, secret, fd, ...)
	-- body
	local obj = objmgr.new_obj()
	obj.uid = uid
	obj.agent = agent
	obj.name = name
	obj.sex = sex
	obj.secret = secret
	obj.fd = fd
	objmgr.add(uid, obj)
end

function _M:rejoin(uid)
end

function _M:afk(uid)
end

function _M:leave(uid, ...)
	-- body
	local gate = ctx:get_gate()
	skynet.call(gate, "lua", "unregister", session)

	return true

	-- local scene = ctx:get_scene()
	-- local session_players = ctx:get_players()
	-- local player = session_players[session]
	-- local balls = player:get_balls()
	-- for k,v in pairs(balls) do
	-- 	scene:leave(v:get_id())
	-- end
	-- for k,v in pairs(session_players) do
	-- 	if k ~= session then
	-- 		local agent = v.agent
	-- 		agent.post.leave({ session = session })
	-- 	end
	-- end
	-- gate.req.unregister(session)
	-- ctx:remove(session)
end

------------------------------------------
-- gameplay协议
--[[
	4 bytes localtime
	4 bytes eventtime		-- if event time is ff ff ff ff , time sync
	4 bytes session
	padding data
]]
-- every frame
local function tick(...)
	-- body
	while true do
		k = k + 1
		local t1 = skynet.now()
		local delta = (t1 - lasttick) / 100.0 -- s
		lasttick = t1
		ctx:update(delta, k)

		skynet.sleep(2)
	end
end

function _M:update(data)
	assert(#data >= 16)
	local session, protocol = string.unpack("<II", data, 9)
	local protocol = string.unpack("<I", data, 13)
	if protocol == 1 then
		-- log.info("protocol 1")
		local time = skynet.now()
		data = string.pack("<I", time) .. data
	elseif protocol == 2 then
		local time = skynet.now()
		data = string.pack("<I", time) .. data
	-- data = data:sub(1, 16)
	-- local ball_data = scene:pack_balls()
	-- data = data .. string.pack("<I", 4 + #ball_data) .. string.pack("<I", protocol) .. ball_data
	end
	local gate = ctx:get_gate()
	gate.post.post(session, data)
end

function _M:query(session)
	local user = users[session]
	-- todo: we can do more
	if user then
		return user.agent.handle
	end
end

function _M:born(session, ...)
	-- body
	local aoi = ctx:get_aoi()
	local scene = ctx:get_scene()
	local ballid = ctx:gen_ball_id()
	local session_players = ctx:get_players()
	local ball = assert(scene:setup_ball(ballid, session))

	local player = assert(session_players[session])
	player:add(ball)

	log.info("player %d born ball %d", session, ballid)

	local pos = ball:get_pos()
	local x, y, z = pos:unpack()
	skynet.send(aoi, "lua", "update", ballid, "wm", x, y, z)

	local radis = ball:get_radis()
	local length = ball:get_length()
	local width = ball:get_width()
	local height = ball:get_height()
	local res = {}
	res.errorcode = errorcode.SUCCESS
	res.session = session
	res.ballid = ball:get_id()
	res.radis = radis
	res.length = length
	res.width = width
	res.height = height
	res.px = ball:pack_sproto_px()
	res.py = ball:pack_sproto_py()
	res.pz = ball:pack_sproto_pz()
	res.dx = ball:pack_sproto_dx()
	res.dy = ball:pack_sproto_dy()
	res.dz = ball:pack_sproto_dz()
	res.vel = ball:pack_sproto_vel()

	for k, v in pairs(session_players) do
		if k ~= session then
			log.info("post born")
			local agent = v:get_agent()
			agent.post.born({bs = {res}})
		end
	end

	return {errorcode = errorcode.SUCCESS, b = res}
end

function _M:opcode(session, args, ...)
	-- body
	local player = session_players[session]
	if player then
		log.info("has this player")
		if args.code == opcodes.OPCODE_PRESSUP then
			local dir = math3d.vector3(0, 0, 1)
			assert(dir)
			player:change_dir(dir)
		elseif args.code == opcodes.OPCODE_PRESSRIGHT then
			local dir = math3d.vector3(1, 0, 0)
			assert(dir)
			player:change_dir(dir)
		elseif args.code == opcodes.OPCODE_PRESSDOWN then
			local dir = math3d.vector3(0, 0, -1)
			assert(dir)
			player:change_dir(dir)
		elseif args.code == opcodes.OPCODE_PRESSLEFT then
			local dir = math3d.vector3(-1, 0, 0)
			assert(dir)
			player:change_dir(dir)
		end
		return {errorcode = errorcode.SUCCESS}
	else
		log.info("no this player")
		return {errorcode = errorcode.FAIL}
	end
end

return _M
