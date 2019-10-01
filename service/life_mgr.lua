local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require "service"
local table_insert = table.insert

local services = {} -- 数组，管理所有服务
local ts = {} -- map,统计服务start次数
local ti = {} -- map,统计init_data次数
local th = {} -- map,统计sayhi

local function launch_uniq(name)
	local addr = skynet.uniqueservice(name)
	local ok = skynet.call(addr, "lua", "start")
	if not ok then
		log.error("call %s start failture.", name)
		return false
	end
	local ok = skynet.call(addr, "lua", "init_data")
	if not ok then
		log.error("call %s init_data failture.", name)
		return false
	end
	local ok = skynet.call(addr, "lua", "sayhi")
	if not ok then
		log.error("call %s sayhi failture.", name)
		return false
	end
	table.insert(services, addr)
	return true
end

local function launch_new(name)
	local addr = skynet.newservice(name)
	local ok = skynet.call(addr, "lua", "start")
	if not ok then
		log.error("call %s failture.", name)
		return false
	end
	table.insert(services, sid_mgr)
	return true
end

local CMD = {}

function CMD.register(handle)
	if ts[handle] == nil then
		table_insert(services, handle)
		ts[handle] = 0
		ti[handle] = 0
		th[handle] = 0
	end
	if ts[handle] == 0 then
		local ok = skynet.call(handle, "lua", "start")
		if not ok then
			log.error("call start failture.")
			return false
		end
		ts[handle] = ts[handle] + 1
	end
	if ti[handle] == 0 then
		local ok = skynet.call(handle, "lua", "init_data")
		if not ok then
			log.error("call init_data failture.")
			return false
		end
		ti[handle] = ti[handle] + 1
	end
	if th[handle] == 0 then
		ok = skynet.call(addr, "lua", "sayhi")
		if not ok then
			log.error("call %s sayhi failture.", name)
			return false
		end
		th[handle] = th[handle] + 1
	end
end

function CMD.uniq(name)
	return launch_uniq(name)
end

function CMD.kill()
	for _, v in pairs(services) do
		skynet.call(v, "lua", "close")
	end
	log.info("kill services")
	-- skynet.exit()
	-- skynet.abort()
end

service.init {
	name = ".LIFE_MGR",
	command = CMD
}
