local skynet = require "skynet"
require("skynet.manager")
-- local log = require "log"
local log = require "chestnut.skynet.log"
local StackTracePlus = require "StackTracePlus"
local traceback = StackTracePlus.stacktrace
local assert = assert

local service = {}

service.NORET = {}

function service.init(mod)
	local funcs = assert(mod.command)
	if mod.info then
		skynet.info_func(function()
			return mod.info
		end)
	end
	skynet.start(function()
		if mod.require then
			local s = mod.require
			for _, name in ipairs(s) do
				service[name] = skynet.uniqueservice(name)
			end
		end
		if mod.init then
			mod.init()
		end
		if mod.name then
			skynet.register(mod.name)
		end
		skynet.dispatch("lua", function (_,_, cmd, ...)
			local f = funcs[cmd]
			if f == nil then
				log.error('Unknown command : [%s].', cmd)
				skynet.response()(false)
				return
			end
			local ok, err = xpcall(f, traceback, ...)
			if ok then
				if err == nil then
					log.error("agent cmd [%s] return result is nil", cmd)
				elseif err ~= service.NORET then
					skynet.retpack(err)
				end
			else
				log.fatal("cmd(%s) error = (%s)", cmd, err)
			end
		end)
	end)
end

return service
