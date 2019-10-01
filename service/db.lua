local skynet = require "skynet"
require "skynet.manager"
local log = require "chestnut.skynet.log"
local db_read = require "db.db_read"
local db_write = require "db.db_write"
local util = require "db.util"
local db = require "db.db"
local QUERY = db.host
local traceback = debug.traceback
local assert = assert

local mode = ...

if mode == "agent" then
	skynet.start(
		function()
			QUERY.start()
			skynet.dispatch(
				"lua",
				function(_, _, cmd, ...)
					local f = assert(QUERY[cmd])
					local ok, err = xpcall(f, traceback, ...)
					if ok then
						if err then
							skynet.retpack(err)
						end
					else
						log.error("db agent cmd = [%s], err = %s", cmd, err)
					end
				end
			)
		end
	)
else
	skynet.start(
		function()
			local agent = {}
			for i = 1, 20 do
				agent[i] = skynet.newservice(SERVICE_NAME, "agent")
			end
			local balance = 1
			skynet.dispatch(
				"lua",
				function(_, _, cmd, ...)
					local d = cmd:sub(1, 1)
					if d == "r" then
						local r = skynet.call(agent[balance], "lua", cmd, ...)
						assert(r)
						skynet.retpack(r)
						balance = balance + 1
						if balance > #agent then
							balance = 2
						end
					elseif d == "w" then
						skynet.send(agent[1], "lua", cmd, ...)
					end
				end
			)
			skynet.register ".DB"
		end
	)
end
