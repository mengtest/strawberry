local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"
local context = require "chestnut.mahjongroom.rcontext"
local CMD = require "chestnut.mahjongroom.cmd"
local service = require "service"
local debug = debug

local id = tonumber(...)
local ctx

skynet.start(function ()
	-- body
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("room cmd [%s] not found.", cmd)
			return
		end
		local traceback = debug.traceback
		local ok, err = xpcall(f, traceback, ctx, ...)
		if ok then
			if err ~= servicecode.NORET then
				skynet.retpack(err)
			end
		else
			log.error(err)
		end
	end)
	ctx = context.new()
	ctx:set_id(id)
end)