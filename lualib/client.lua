local skynet = require "skynet"
local socket = require "skynet.socketdriver"
local log = require "chestnut.skynet.log"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local servicecode = require "enum.servicecode"
local objmgr = require "objmgr"
local assert = assert
local string_pack = string.pack
local max = 2 ^ 16 - 1
local handler = {}
local host = sprotoloader.load(1):host "package"
local send_request = host:attach(sprotoloader.load(2))
local response_session = 0
local response_session_name = {}

local version = 1
local REQUEST = {}
local RESPONSE = {}

local function request(name, args, response)
	log.info("agent request [%s]", name)
    local f = REQUEST[name]
    if f then
		local traceback = debug.traceback
	    local ok, result = xpcall(f, traceback, ctx, args)
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

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		local msg, sz = skynet.unpack(msg, sz)
		if sz > 0 then
			return host:dispatch(msg, sz)
		else
			assert(false)
		end
	end,
	dispatch = function (_, session, type, ...)
		if type == "REQUEST" then
			local fd = session
			local obj = objmgr.get_by_fd(fd)
			local traceback = debug.traceback
			local ok, result = xpcall(request, traceback, obj, ...)
			if ok then
				if result then
					if login_type == 'so' then
						ctx:send_package(result)
					else
						ctx:send_package_gate("push_client", result)
					end
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

local function send_package_id(id, pack)
	-- body
	assert(id and pack)
	local package = string_pack(">s2", pack)
	socket.write(id, package)
end

local function send_package_gate(gate, fd, pack)
	skynet.send(gate, "lua", "push_client", fd, pack)
end

local cls = {}

function cls.init(mod)
end

function cls.request()
	return REQUEST
end

function cls.response()
	return RESPONSE
end

function cls.send_request(obj, name, args)
	-- body
	assert(obj.authed)
	local fd = assert(obj.fd)
	response_session = response_session + 1 % max
	response_session_name[response_session] = name
	local request = send_request(name, args, response_session)
	send_package_id(fd, request)
end

function cls.send_request_gate(obj, name, args)
	-- body
	assert(obj.authed)
	response_session = response_session + 1 % max
	response_session_name[response_session] = name
	local request = send_request(name, args, self.response_session)
	send_package_gate(obj.gate, obj.fd, request)
end

function cls:send_request(name, args)
	-- body
	if not self.logined or not self.authed then
		return
	end
	
	self:send_request_id(fd, name, args)
end

function cls:push(name, args, ... )
	-- body
	if not self.logined or not self.authed then
		return
	end
	assert(name)

	local request = self._send_request(name, args, 0)
	cls.send_package(self, request)
end

function cls.push2objs(objs, name, args, ... )
	-- body
	for k,v in pairs(objs) do
		cls.push(v, name, args, ...)
	end
end

function cls:get_name_by_session(session)
	-- body
	return self.response_session_name[session]
end

return cls