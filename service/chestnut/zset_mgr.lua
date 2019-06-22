local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require "service"
local savedata = require "savedata"
local assert = assert

local users = {}
local handles = {}
local CMD = {}
local SUB = {}

local function save_data()
end

function SUB.save_data( ... )
	-- body
end

function CMD.start()
	-- body
	local handle = skynet.newservice('chestnut/zsetd')
	skynet.call(handle, 'lua', 'start', 'power')
	handles['power'] = handle
	savedata.init {
		command = SUB
	}
	savedata.subscribe()
	return true
end

function CMD.init_data()
	-- body
	for _,v in pairs(handles) do
		skynet.call(v, 'lua', 'init_data')
	end
	return true
end

function CMD.sayhi()
	-- body
	return true
end

function CMD.close()
	-- body
	-- 存在线数据
	for _,v in pairs(handles) do
		skynet.call(v, 'lua', 'close')
	end
	save_data()
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

-- CMD
function CMD.push(uid, key)
	-- body
	local u = users[uid]
	if u then
		u.key = key
	else
		assert(false)
	end
	ld:sort()
	return ld:bsearch(u)
end

function CMD.bsearch(uid, ... )
	-- body
	local u = users[uid]
	return ld:bsearch(u)
end

function CMD.range(start, stop)
	-- body
	return ld:range(start, stop)
end

function CMD.nearby(rank)
	-- body
	return ld:nearby(rank)
end

service.init {
	name = '.ZSET_MGR',
	command = CMD
}
