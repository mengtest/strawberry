local skynet = require "skynet"
local savedata = require "savedata"
local command = require "command"
local CMD = require "cmd"

-- function CMD:start()
-- 	savedata.init {}
-- 	savedata.subscribe()
-- 	return true
-- end

-- function CMD:init_data()
-- 	return true
-- end

-- function CMD:sayhi(...)
-- 	return true
-- end

-- function CMD:save_data()
-- end

-- function CMD:close(...)
-- 	return true
-- end

-- function CMD:kill(...)
-- 	skynet.exit()
-- end

------------------------------------------
-- 房间协议
function CMD:create(uid, mode, args, ...)
	-- body
	return self:create(uid, args, ...)
end

function CMD:on_join(agent, ...)
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

function CMD:born(session, ...)
	-- body
	return self:born(session, ...)
end

function CMD:opcode(session, args, ...)
	-- body
	return self:opcode(session, args, ...)
end

return CMD
