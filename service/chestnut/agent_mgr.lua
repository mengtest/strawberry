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
local q = queue()                 -- 未用的agent
local users = {}                  -- uid:u
local agents = {}                 -- agent:count
local MAX_U = 5

local function enqueue(u)
	-- body
	q:enqueue(u)
end

local function dequeue()
	-- body
	if #q > 0 then
		return q:dequeue()
	else
		local u = {}
		local addr = skynet.newservice("chestnut/agent")
		skynet.call(addr, 'lua', 'start')
		u.addr = addr
		return u
	end
end

local CMD = {}

------------------------------------------
-- 游戏设计
function CMD.enter(uid)
	-- body
	assert(uid)
	local u = users[uid]
	if false then
		-- 重连
		skynet.call(u.addr, "lua", "sayhi", true)
		return u.addr
	else
		local u = cs(dequeue)
		u.uid = uid		
		users[uid] = u
		skynet.call(u.addr, "lua", "sayhi", false)
		local cnt = agents[u.addr]
		if cnt then
			agents[u.addr] = cnt + 1
		else
			agents[u.addr] = 1
		end
		return u.addr
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
	local cnt = agents[u.addr]
	agents[u.addr] = cnt - 1
	cs(enqueue, u)
	users[uid] = nil
	return true
end

service.init {
	name = '.AGENT_MGR',
	command = CMD
}

