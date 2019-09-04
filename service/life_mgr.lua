local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local service = require "service"

local services = {}

local function launch_uniq(name)
	local addr = skynet.uniqueservice(name)
	local ok = skynet.call(addr, "lua", "start")
	if not ok then
		log.error("call %s start failture.", name)
		return false
	end
	ok = skynet.call(addr, "lua", "init_data")
	if not ok then
		log.error("call %s init_data failture.", name)
		return false
	end
	ok = skynet.call(addr, "lua", "sayhi")
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

function CMD.register()
end

function CMD.uniq(name)
	-- body
	return launch_uniq(name)
end

function CMD.kill()
	-- body
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
