local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"
local context = require "chestnut.mahjongroom.rcontext"

local CMD = {}

function CMD:start()
	-- body
	return self:start()
end

function CMD:init_data()
	-- body
	return true
	-- return self:init_data()
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
	skynet.exit()
end

------------------------------------------
-- 房间协议
function CMD:create(uid, args, ... )
	-- body
	return self:create(uid, args, ...)
end

function CMD:on_join(agent, ... )
	-- body
	local res = self:join(agent.uid, agent.agent, agent.name, agent.sex)
	return res
end

function CMD:on_rejoin(args)
	-- body
	return self:rejoin(args.uid, args.agent)
end

function CMD:on_afk(uid)
	-- body
	return self:afk(uid)
end

function CMD:on_leave(uid)
	-- body
	return self:leave(uid)
end

------------------------------------------
-- 麻将协议 request
function CMD:on_ready(args, ... )
	-- body
	return self:ready(args.idx)
end

function CMD:on_lead(args, ... )
	-- body
	return self:lead(args.idx, args.card, args.isHoldcard)
end

function CMD:on_call(args, ... )
	-- body
	return self:call(args.op)
end

function CMD:on_step(args, ... )
	-- body
	local ok, res = xpcall(context.step, debug.msgh, self, args.idx)
	if not ok then
		log.error(res)
		local res = {}
		res.servicecode = servicecode.SERVER_ERROR
		return res
	else
		return res
	end
end

function CMD:on_restart(args, ... )
	-- body
	self:restart(args.idx)
	local res = {}
	res.servicecode = servicecode.SUCCESS
	return res
end

function CMD:on_rchat(args, ... )
	-- body
	self:chat(args)
	local res = {}
	res.servicecode = servicecode.SUCCESS
	return res
end

function CMD:on_xuanpao(args, ... )
	-- body
	return self:xuanpao(args)
end

function CMD:on_xuanque(args, ... )
	-- body
	return self:xuanque(args)
end

return CMD