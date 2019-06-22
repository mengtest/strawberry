local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "chestnut.servicecode"
local traceback = debug.traceback
local xpcall = xpcall

local CMD = {}

------------------------------------------
-- 服务manager事件
function CMD:start(channel_id)
	-- body
	return self:start(channel_id)
end

function CMD:init_data()
	-- body
	return self:init_data()
end

function CMD:sayhi(...)
	-- body
	return self:sayhi(...)
end

function CMD:save_data()
	-- body
	self:save_data()
end

function CMD:close()
	-- body
	-- will be kill
	return self:close()
end

function CMD:kill()
	-- body
	assert(self)
	skynet.exit()
end

-- end
------------------------------------------

------------------------------------------
-- 房间用户协议
-- call by room_mgr
function CMD:create(uid, args)
	-- body
	return self:create(uid, args)
end

-- call by agent
function CMD:on_join(agent)
	-- body
	local res = self:join(agent.uid, agent.agent, agent.name, agent.sex)
	return res
end

-- send by agent
function CMD:join(args)
	-- body
	assert(self)
	assert(args.errorcode == 0)
	return servicecode.NORET
end

-- call by agent
function CMD:on_rejoin(args)
	-- body
	return self:rejoin(args.uid, args.agent)
end

-- send by agent
function CMD:rejoin(args)
	-- body
	assert(self)
	assert(args.errorcode == 0)
	return servicecode.NORET
end

-- call by agent
function CMD:on_leave(uid)
	-- body
	return self:leave(uid)
end

-- send by agent
function CMD:leave(args)
	-- body
	assert(self)
	assert(args.errorcode == servicecode.SUCCESS)
	return servicecode.NORET
end

-- call by agent
function CMD:on_afk(uid)
	-- body
	return self:afk(uid)
end

function CMD:afk(args)
	-- body
	assert(self)
	assert(args.errorcode == servicecode.SUCCESS)
	return servicecode.NORET
end

-- call by room_mgr
function CMD:recycle(args)
	-- body
	return self:recycle(args)
end

-- 结束协议
------------------------------------------


------------------------------------------
-- 德州请求协议
function CMD:on_ready(args)
	-- body
	local ok, err = xpcall(self.ready, traceback, self, args.idx)
	if ok then
		return err
	else
		log.error(err)
		local res = {}
		res.errorcode = 1
		return res
	end
end

function CMD:on_call(args)
	-- body
	local ok, err = xpcall(self.call, traceback, self, args.idx, args.opcode, args)
	if ok then
		return err
	else
		log.error(err)
		local res = {}
		res.errorcode = 1
		return res
	end
end

function CMD:on_step(args)
	-- body
	local ok, err = xpcall(self.step, traceback, self, args.idx)
	if ok then
		return err
	else
		log.error(err)
		local res = {}
		res.errorcode = 1
		return res
	end
end

function CMD:on_restart(args)
	-- body
	return self:restart(args.idx)
end

function CMD:on_joined(args)
	-- body
	return self:joinedx(args.idx)
end

-- 结束协议
------------------------------------------

------------------------------------------
-- 德州响应协议
function CMD:take_turn(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:call(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:shuffle(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:lead(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:deal(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:ready(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:over(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:restart(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:take_restart(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:settle(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:final_settle(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

function CMD:roomover(args)
	-- body
	assert(self and args)
	return servicecode.NORET
end

-- 德州响应协议over
------------------------------------------


return CMD