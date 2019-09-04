local skynet = require "skynet"
local mc = require "skynet.multicast"
local savedata = require("savedata")

local CMD = {}

function CMD:start(channel_id, ... )
	-- body
	savedata.init {

	}
	return true
	-- local channel = mc.new {
	-- 	channel = channel_id,
	-- 	dispatch = function (_, _, cmd, ...)
	-- 		-- body
	-- 		local f = assert(CMD[cmd])
	-- 		local ok, result = pcall(f, self, ... )
	-- 		if not ok then
	-- 			log.error(result)
	-- 		end
	-- 	end
	-- }
	-- channel:subscribe()
	-- return self:start()
end

function CMD:init_data()
	return true
end

function CMD:sayhi(...)
	return true
end

function CMD:save_data()
end

function CMD:close( ... )
	-- body
	return true
end

function CMD:kill( ... )
	-- body
	skynet.exit()
end

------------------------------------------
-- 房间协议
function CMD:create(uid, mode, args, ... )
	-- body
	return self:create(uid, args, ...)
end

function CMD:on_join(agent, ... )
	-- body
	return self:join(agent.uid, agent.agent, agent.name, agent.sex, agent.secret)
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
-- gameplay 协议
function CMD:query(session)
	return self:query(session)
end

function CMD:born(session, ... )
	-- body
	return self:born(session, ...)
end

function CMD:opcode(session, args, ... )
	-- body
	return self:opcode(session, args, ...)
end

return CMD