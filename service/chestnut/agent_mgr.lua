local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local skynet_queue = require "skynet.queue"
local queue = require "chestnut.queue"
local util = require "common.utils"
local service = require "service"
local traceback = debug.traceback
local assert = assert

local cs = skynet_queue()
local leisure_agent = queue()     -- 未用的agent
local users = {}                  -- 已经用了的agent
local offusers = {}               -- 离线的agent

local function enqueue(agent)
	-- body
	leisure_agent:enqueue(agent)
end

local function dequeue()
	-- body
	if #leisure_agent > 0 then
		return leisure_agent:dequeue()
	end
end

local CMD = {}

function CMD.start()
	-- body
	local init_agent_num = 10
	for _=1,init_agent_num do
		local agent = {}
		local addr = skynet.newservice("chestnut/agent")
		agent.addr = addr
		enqueue(agent)
	end
	for _,v in pairs(leisure_agent) do
		local ok = skynet.call(v.addr, "lua", "start")
		assert(ok)
	end
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
	-- 存在线数据
	for _,v in pairs(users) do
		skynet.call(v.addr, 'lua', 'close')
	end
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

------------------------------------------
-- 游戏设计
function CMD.enter(uid)
	-- body
	assert(uid)
	local u = users[uid]
	assert(not u)
	if u and u.addr then
		assert(false)
		if u.cancel then
			u.cancel()
		end
		skynet.call(u.addr, "lua", "sayhi", false)
		return 0
	else
		if #leisure_agent <= 0 then
			return -1
		else
			local agent = cs(dequeue)
			agent.uid = uid
			agent.cancel = nil
			users[uid] = agent
			skynet.call(agent.addr, "lua", "sayhi", true)
			return agent.addr
		end
	end
end

-- 次方法实现有问题，暂时不理
function CMD.exit(uid)
	-- body
	assert(uid)
	local u = users[uid]
	if u then
		local cancel = util.set_timeout(100 * 60 * 60, function ()
			-- body
			cs(enqueue, u.addr)
			users[uid] = nil
		end)
		u.cancel = cancel
		return true
	end
	return false
end

function CMD.exit_at_once(uid)
	-- body
	local u = assert(users[uid])
	u.uid = nil
	cs(enqueue, u)
	users[uid] = nil
	return true
end

service.init {
	name = '.AGENT_MGR',
	command = CMD
}

