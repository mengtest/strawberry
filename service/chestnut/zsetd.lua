local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require "service"
local zset = require "zset"
local db = require "db.db"
local savedata = require "savedata"
local table_dump = require "luaTableDump"
local assert = assert
local ldname
local set
local users = {}
local CMD = {}
local SUB = {}

local function save_data()
end

function SUB.save_data()
	save_data()
end

function CMD.start(name)
	-- body
	ldname = name
	savedata.init {
		command = SUB
	}
	savedata.subscribe()
	return true
end

function CMD.init_data()
	set = zset.new()
	local res = db.read_zset(ldname)
	-- skynet.error(table_dump(res))
	for _, r in pairs(res.db_zset) do
		set:add(r.power, {uid = r.uid})
	end
	return true
end

function CMD.sayhi()
	return true
end

function CMD.close()
	save_data()
	return true
end

function CMD.kill()
	skynet.exit()
end

-- 访问数据
function CMD.login(uid, agent, key, ...)
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

function CMD.bsearch(uid, ...)
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
	name = ".ZSETD",
	command = CMD
}
