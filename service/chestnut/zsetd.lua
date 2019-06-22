local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require "service"
local zset = require "zset"
local assert = assert

local users = {}
local ldname
local CMD = {}
local SUB = {}

local function save_data()
end

function SUB.save_data( ... )
	-- body
end




function CMD.start(name)
	-- body
	ldname = name
	return true
end

function CMD.init_data()
	-- body
	return true
end

function CMD.sayhi()
	-- body
	return true
end

function CMD.close()
	-- body
	save_data()
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

-- 访问数据
function CMD.login(uid, agent, key, ... )
	-- body
	local u = users[uid]
	if u then
		u.agent = agent
		u.key = key
	else
		u = {
			uid = uid,
			agent = agent,
			key = key
		}
		users[uid] = u
		ld:push(u)
	end
end

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
	name = '.ZSETD',
	command = CMD
}
