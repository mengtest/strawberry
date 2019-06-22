local skynet = require "skynet"
local debug = debug
local string_format = string.format
local skynet_error = skynet.error
local daemon = skynet.getenv("daemon")
local test = true
local address

local _M = {}

_M.DEBUG   = 0
_M.INFO    = 1
_M.WARNING = 2
_M.ERROR   = 3
_M.FATAL   = 4

local function get_logger()
	if not address then
		local dir  = skynet.getenv 'xlogpath'
		local roll = skynet.getenv 'xlogroll'
		local level = 0
		address = skynet.uniqueservice("xlogd", dir, roll, level)
	end
	return address
end

local function log(level, file, line, fields, msg)
	local level = level
	local time  = os.date()
	local server = SERVICE_NAME
	local data = {
		logger = 'default',
		time   =  os.date(),
		level  = level,
		server = SERVICE_NAME,
		file   = file,
		line   = line,
		fields = fields,
		msg    = msg
	}
	local logger = get_logger()
	skynet.send(logger, 'lua', 'log', data)
end

function _M.fields(fields)
	-- body
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline

	return {
		debug = function (fmt, ...)
			-- body
			local msg  = string_format(fmt, ...)
			log('debug', file, line, fields, msg)
		end,
		info = function (fmt, ... )
			-- body
			local msg  = string_format(fmt, ...)
			log('debug', file, line, fields, msg)
		end,
		warning = function (fmt, ... )
			-- body
			local msg  = string_format(fmt, ...)
			log('debug', file, line, fields, msg)
		end,
		error = function (fmt, ...)
			local msg  = string_format(fmt, ...)
			log('debug', file, line, fields, msg)
		end,
		fatal = function (fmt, ...)
			local msg  = string_format(fmt, ...)
			log('debug', file, line, fields, msg)
		end
	}
end

function _M.debug(fmt, ...)
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline
	local msg  = string_format(fmt, ...)
	log('debug', file, line, {}, msg)
end

function _M.info(fmt, ...)
	local msg  = string_format(fmt, ...)
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline
	log('info', file, line, {}, msg)
end

function _M.warning(fmt, ...)
	local msg = string_format(fmt, ...)
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline
	log('warning', file, line, {}, msg)
end

function _M.error(fmt, ...)
	local msg = string_format(fmt, ...)
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline
	log('error', file, line, {}, msg)
end

function _M.fatal(fmt, ...)
	local msg = string_format(fmt, ...)
	local info = debug.getinfo(2)
	local file = info.short_src
	local line = info.currentline
	log('fatal', file, line, {}, msg)
end

return _M
