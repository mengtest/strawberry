local skynet = require "skynet"
local snax = require "snax"
local aoiaux = require "aoiaux"
local log = require "log"
local room
local aux

local objects = {}

local CMD = {}

local function aoi_Callback(watcher, marker, ... )
	-- body
	room.post.aoi_message(watcher, marker)
	-- log.info("lua aoi_Callback watcher:%d, marker:%d", watcher, marker)
	-- log.info("px:%d, py:%d, pz:%d", objects[watcher].px, objects[watcher].py, objects[watcher].pz)
	-- log.info("px:%d, py:%d, pz:%d", objects[marker].px, objects[marker].py, objects[marker].pz)	
end

local function update_obj(id, ... )
	-- body
	objects[id].px = objects[id].px + objects[id].vx
	if objects[id].px < 0 then
		objects[id].px = objects[id].px + 100
	end
	if objects[id].px > 100 then
		objects[id].px = objects[id].px - 100
	end
	objects[id].py = objects[id].py + objects[id].vy
	if objects[id].py < 0 then
		objects[id].py = objects[id].py + 100
	end
	if objects[id].py > 100 then
		objects[id].py = objects[id].py - 100
	end	
	aux:update(id, objects[id].mode, objects[id].px, objects[id].py, objects[id].pz)
end

local function test( ... )
	-- body
	for i=1,100 do
		if i < 50 then	
			for j=1,4 do
				update_obj(j)
			end
		elseif i == 50 then
			-- aux:update(4, "d", objects[4].px, objects[4].py, objects[4].pz)
		else
			for j=1,3 do
				update_obj(j)
			end
		end
		aux:message(aoi_Callback)
	end
end

function CMD.update(id, mode, x, y, z, ... )
	-- body
	aux:update(id, mode, x, y, z)
end

function CMD.message( ... )
	-- body
	aux:message(aoi_Callback)
end

function CMD.start(conf, ... )
	-- body
	local handle = conf.handle
	room = snax.bind(handle , "room")
	return true
end

skynet.start(function ( ... )
	-- body
	skynet.dispatch("lua", function(_,_, cmd, subcmd, ...)
		-- log.info("aoi cmd: %s", cmd)
		local f = CMD[cmd]
		local r = f(subcmd, ... )
		if r then
			skynet.ret(skynet.pack(r))
		end
	end)
	aux = aoiaux()
	aux:test()
	
	-- objects = {
	-- 	{
	-- 		px = 40,
	-- 		py = 0,
	-- 		pz = 0,
	-- 		vx = 0,
	-- 		vy = 1,
	-- 		vz = 0,
	-- 		mode = 'w',
	-- 	},
	-- 	{
	-- 		px = 42,
	-- 		py = 100,
	-- 		pz = 0,
	-- 		vx = 0,
	-- 		vy = -1,
	-- 		vz = 0,
	-- 		mode = 'wm',
	-- 	},
	-- 	{
	-- 		px = 0,
	-- 		py = 40,
	-- 		pz = 0,
	-- 		vx = 1,
	-- 		vy = 0,
	-- 		vz = 0,
	-- 		mode = 'w',
	-- 	},
	-- 	{
	-- 		px = 100,
	-- 		py = 45,
	-- 		pz = 0,
	-- 		vx = -1,
	-- 		vy = 0,
	-- 		vz = 0,
	-- 		mode = 'wm',
	-- 	}
	-- }
	-- -- tick()
	-- test()
	-- skynet.fork(tick)
end)