local skynet = require "skynet"
local client = require "client"

local RESPONSE = client.response()

function RESPONSE:handshake(args)
	-- body
	assert(self)
	assert(args.errorcode == 0)
end

function RESPONSE:join(args)
	-- body
	assert(self)
	local room = self:get_room()
	skynet.send(room, "lua", "join", args)
end

function RESPONSE:rejoin(args)
end

function RESPONSE:offline(args)
end

function RESPONSE:leave(args, ... )
	-- body
	assert(self)
end

------------------------------------------
-- 麻将响应模块
function RESPONSE:take_ready(args)
end

function RESPONSE:take_turn(args)
	-- body
	self.systems.room:forward_room_rsp("take_turn", args)
end

function RESPONSE:deal(args, ... )
	-- body
	self.systems.room:forward_room_rsp("deal", args)
end

function RESPONSE:ready(args, ... )
	-- body
	self.systems.room:forward_room_rsp("ready", args)
end

function RESPONSE:peng(args, ... )
	-- body
	self.systems.room:forward_room_rsp("peng", args)
end

function RESPONSE:gang(args, ... )
	-- body
	self.systems.room:forward_room_rsp("gang", args)
end

function RESPONSE:hu(args, ... )
	-- body
	self.systems.room:forward_room_rsp("hu", args)
end

function RESPONSE:call(args, ... )
	-- body
	self.systems.room:forward_room_rsp("call", args)
end

function RESPONSE:shuffle(args, ... )
	-- body
	self.systems.room:forward_room_rsp("shuffle", args)
end

function RESPONSE:dice(args, ... )
	-- body
	self.systems.room:forward_room_rsp("dice", args)
end

function RESPONSE:lead(args, ... )
	-- body
	self.systems.room:forward_room_rsp("lead", args)
end

function RESPONSE:over(args, ... )
	-- body
	self.systems.room:forward_room_rsp("over", args)
end

function RESPONSE:restart(args, ... )
	-- body
	self.systems.room:forward_room_rsp("restart", args)
end

function RESPONSE:rchat(args, ... )
	-- body
	self.systems.room:forward_room_rsp("rchat", args)
end

function RESPONSE:take_restart(args, ... )
	-- body
	self.systems.room:forward_room_rsp("take_restart", args)
end	

function RESPONSE:take_xuanpao(args, ... )
	-- body
	self.systems.room:forward_room_rsp("take_xuanpao", args)
end

function RESPONSE:take_xuanque(args, ... )
	-- body
	self.systems.room:forward_room_rsp("take_xuanque", args)
end

function RESPONSE:xuanque(args, ... )
	-- body
	self.systems.room:forward_room_rsp("xuanque", args)
end

function RESPONSE:xuanpao(args, ... )
	-- body
	self.systems.room:forward_room_rsp("xuanpao", args)
end

function RESPONSE:settle(args, ... )
	-- body
	self.systems.room:forward_room_rsp("settle", args)
end

function RESPONSE:final_settle(args, ... )
	-- body
	self.systems.room:forward_room_rsp("final_settle", args)
end

function RESPONSE:roomover(args, ... )
	-- body
	self.systems.room:forward_room_rsp("roomover", args)
end

-- 麻将响应模块over
------------------------------------------

------------------------------------------
-- 大佬2响应模块
function RESPONSE:big2take_turn(args)
	-- body
	self.systems.room:forward_room_rsp("take_turn", args)
end

function RESPONSE:big2call(args)
	-- body
	self.systems.room:forward_room_rsp("call", args)
end

-- 此协议已经(deprecated)
function RESPONSE:big2shuffle(args)
	-- body
	self.systems.room:forward_room_rsp("shuffle", args)
end

function RESPONSE:big2deal(args)
	-- body
	self.systems.room:forward_room_rsp("deal", args)
end

function RESPONSE:big2ready(args)
	-- body
	self.systems.room:forward_room_rsp("ready", args)
end

function RESPONSE:big2over(args)
	-- body
	self.systems.room:forward_room_rsp("over", args)
end

function RESPONSE:big2restart(args)
	-- body
	self.systems.room:forward_room_rsp("restart", args)
end

function RESPONSE:big2settle(args)
	-- body
	self.systems.room:forward_room_rsp("settle", args)
end

function RESPONSE:big2final_settle(args)
	-- body
	self.systems.room:forward_room_rsp("final_settle", args)
end

function RESPONSE:big2match(args)
	-- body
	assert(self)
	assert(args)
	-- self.systems.room:forward_room_rsp("match", args)
end

function RESPONSE:big2rejoin(args)
	-- body
	self.systems.room:forward_room_rsp("rejoin", args)
end

function RESPONSE:big2join(args)
	-- body
	self.systems.room:forward_room_rsp("join", args)
end

function RESPONSE:big2leave(args)
	-- body
	self.systems.room:forward_room_rsp("leave", args)
end

function RESPONSE:big2take_ready(args)
	-- body
	self.systems.room:forward_room_rsp("take_ready", args)
end

-- 大佬2响应模块
------------------------------------------

------------------------------------------
-- 德州响应模块
function RESPONSE:pokertake_turn(args)
	-- body
	self.systems.room:forward_room_rsp("take_turn", args)
end

function RESPONSE:pokercall(args)
	-- body
	self.systems.room:forward_room_rsp("call", args)
end

-- (deprecated)
function RESPONSE:pokershuffle(args)
	-- body
	self.systems.room:forward_room_rsp("shuffle", args)
end

function RESPONSE:pokerdeal(args)
	-- body
	self.systems.room:forward_room_rsp("deal", args)
end

function RESPONSE:pokertake_ready(args)
	-- body
	self.systems.room:forward_room_rsp("take_ready", args)
end

function RESPONSE:pokerready(args)
	-- body
	self.systems.room:forward_room_rsp("ready", args)
end

function RESPONSE:pokerover(args)
	-- body
	self.systems.room:forward_room_rsp("over", args)
end

function RESPONSE:pokertake_restart(args)
	-- body
	self.systems.room:forward_room_rsp("take_restart", args)
end

function RESPONSE:pokerrestart(args)
	-- body
	self.systems.room:forward_room_rsp("restart", args)
end

function RESPONSE:pokersettle(args)
	-- body
	self.systems.room:forward_room_rsp("settle", args)
end

function RESPONSE:pokermatch(args)
	-- body
	self.systems.room:forward_room_rsp("match", args)
end

function RESPONSE:pokerrejoin(args)
	-- body
	self.systems.room:forward_room_rsp("rejoin", args)
end

function RESPONSE:pokerjoin(args)
	-- body
	self.systems.room:forward_room_rsp("join", args)
end

function RESPONSE:pokerleave(args)
	-- body
	self.systems.room:forward_room_rsp("leave", args)
end

-- 德州响应模块
------------------------------------------

return RESPONSE