local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require "service"
local savedata = require "savedata"
local assert = assert
local handles = {}
local CMD = {}
local SUB = {}

local function save_data()
end

function SUB.save_data()
	save_data()
end

function CMD.start()
	log.info("zset_mgr start")
	local handle = skynet.newservice("chestnut/zsetd")
	skynet.call(handle, "lua", "start", "power")
	handles["power"] = handle
	-- savedata.init {
	-- 	command = SUB
	-- }
	-- savedata.subscribe()
	return true
end

function CMD.init_data()
	log.info("zset_mgr init_data")
	for _, v in pairs(handles) do
		skynet.call(v, "lua", "init_data")
	end
	return true
end

function CMD.sayhi()
	for _, v in pairs(handles) do
		skynet.call(v, "lua", "sayhi")
	end
	return true
end

function CMD.close()
	-- 存在线数据
	for _, v in pairs(handles) do
		skynet.call(v, "lua", "close")
	end
	-- save_data()
	return true
end

function CMD.kill()
	skynet.exit()
end

-- CMD
function CMD.get(name)
	return handles[name]
end

service.init {
	name = ".ZSET_MGR",
	command = CMD
}
