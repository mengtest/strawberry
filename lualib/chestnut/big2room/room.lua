package.path = "./module/dezhou/big2room/?.lua;./module/dezhou/lualib/?.lua;"..package.path
local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "chestnut.servicecode"
local context = require "room_context"
local CMD = require "cmd"
local debug = debug
local traceback = debug.traceback

local id = tonumber(...)
local ctx

skynet.start(function ()
	-- body
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd])
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