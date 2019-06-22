-- if client for this node has 
local skynet = require "skynet"
local snowflake = require "chestnut.snowflake"
local service = require "service"
local host = require 'xlog.host'
local tableDump = require 'luaTableDump'

local cfg = {...}
local logger
local CMD = {}

local function tolevelid(level) 
	if level == 'debug' then
		return 0
	elseif level == 'info' then
		return 1
	elseif level == "warning" then
		return 2
	elseif level == 'error' then
		return 3
	elseif level == "fatal" then
		return 4
	else
		return -1
	end
end

local function loop()
	while true do
		logger:flush()
		skynet.sleep(100 * 20)
	end
end

function CMD.log(data)
	-- body
	if not data then
		return service.NORET
	end
	-- print(tableDump(data))
	local time   =  assert(data.time)
	local level  =  assert(data.level)
	local server =  assert(data.server)
	local file   =  assert(data.file)
	local line   =  assert(data.line)
	local tmp    =  ''
	if type(data.fields) == 'table' then
		for k,v in pairs(data.fields) do
			tmp = tmp .. string.format( "[%s = %s]", tostring(k), tostring(v))
		end
	end
	local msg    = assert(data.msg)
	local fs = string.format("[time = %s][level = %s][server = %s][file = %s][line = %s]%s[msg = %s]\n", time, level, server, file, line, tmp, msg)

	logger:log(tolevelid(level), fs)
	return service.NORET
end

function CMD.append(data)
end

service.init {
	init = function ()
		-- print(tableDump(cfg))
		logger = host(cfg[1], tonumber(cfg[2]), tonumber(cfg[3]))
		skynet.fork(loop)
	end,
	command = CMD
}