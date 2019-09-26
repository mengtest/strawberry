local skynet = require "skynet"
local socket = require "skynet.socketdriver"
local log = require "chestnut.skynet.log"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local servicecode = require "enum.servicecode"
local assert = assert
local string_pack = string.pack
local max = 2 ^ 16 - 1
local handler = {}
local host = sprotoloader.load(1):host "package"
local send_request = host:attach(sprotoloader.load(2))
local response_session = 0
local response_session_name = {}
local traceback = debug.traceback
local version = 1
local REQUEST = require "request"
local RESPONSE = require "response"
local login_type = "so"
local gate
local _middlewares = {}

local function request(obj, name, args, response)
	-- log.info("agent request [%s]", name)
	local f = REQUEST[name]
	if f then
		local ok, result = xpcall(f, traceback, obj, args)
		if ok then
			if result then
				return response(result)
			else
				log.error("agent request [%s] result is nil", name)
			end
		else
			log.error("agent request [%s], error = [%s]", name, result)
		end
	else
		log.error("agent request [%s] is nil", name)
	end
end

local function response(session, args)
	-- body
	local name = ctx:get_name_by_session(session)
	-- log.info("agent response [%s]", name)
	local f = RESPONSE[name]
	if f then
		local ok, result = pcall(f, ctx, args)
		if not ok then
			log.error(result)
		end
	else
		log.error("agent response [%s] is nil.", name)
	end
end

local function send_package_id(id, pack)
	-- body
	assert(id and pack)
	local package = string_pack(">s2", pack)
	socket.send(id, package)
end

local function send_package_gate(fd, pack)
	skynet.send(gate, "lua", "push_client", fd, pack)
end

local function get_name_by_session(session)
	-- body
	return response_session_name[session]
end

skynet.init(
	function()
	end
)

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function(msg, sz)
		if sz > 0 then
			return host:dispatch(msg, sz)
		else
			assert(false)
		end
	end,
	dispatch = function(fd, _, type, ...)
		skynet.ignoreret()
		if type == "REQUEST" then
			-- local fd = session
			local traceback = debug.traceback
			local ok, result = xpcall(request, traceback, fd, ...)
			if ok then
				if result then
					if login_type == "so" then
						-- log.info("send response")
						send_package_id(fd, result)
					else
						send_package_gate(fd, result)
					end
				else
					log.error("result is nil")
				end
			else
				log.error("agent dispatch error:")
				log.error(result)
			end
		elseif type == "RESPONSE" then
			pcall(response, ...)
		else
			assert(false)
		end
	end
}

local _M = {}

function _M.init(mod)
end

function _M.request()
	return REQUEST
end

function _M.response()
	return RESPONSE
end

function _M.use(middleware)
	table.insert(_middlewares, middleware())
end

function _M.send_request(obj, name, args)
	-- body
	assert(obj.authed)
	local fd = assert(obj.fd)
	response_session = response_session + 1 % max
	response_session_name[response_session] = name
	local request = send_request(name, args, response_session)
	send_package_id(fd, request)
end

function _M.send_request_gate(obj, name, args)
	-- body
	assert(obj.authed)
	response_session = response_session + 1 % max
	response_session_name[response_session] = name
	local request = send_request(name, args, self.response_session)
	send_package_gate(obj.fd, request)
end

function _M.push(obj, name, args)
	-- body
	assert(obj.authed)
	assert(name)
	local fd = assert(obj.fd)

	if login_type == "so" then
		local request = send_request(name, args, 0)
		send_package_id(obj.fd, request)
	end
end

function _M.push2objs(objs, name, args, ...)
	-- body
	for k, v in pairs(objs) do
		_M.push(v, name, args, ...)
	end
end

return _M
