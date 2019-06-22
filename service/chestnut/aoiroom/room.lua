local skynet = require "skynet"
require "skynet.manager"
local crypt = require "skynet.crypt"
local log = require "skynet.log"

local list = require "list"
local errorcode = require "errorcode"
local context = require "room.context"
local CMD = require "room.cmd"

-- context variable
local id = tonumber( ... )
local ctx
local k = 0
local lasttick = 0


skynet.start(function ( ... )
	-- body
	skynet.dispatch("lua", function(_,_, cmd, subcmd, ...)
		local f = CMD[cmd]
		local r = f(ctx, subcmd, ... )
		if r ~= nil then
			skynet.ret(skynet.pack(r))
		end
	end)

	ctx = context.new(id)
	
	-- local aoi = skynet.newservice("aoi")
	-- local battle = skynet.launch("battle")

	-- ctx:set_aoi(aoi)
	-- ctx:set_battle(battle)
end)

