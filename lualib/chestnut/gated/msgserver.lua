local skynet = require "skynet"
local netpack = require "skynet.netpack"
local gateserver = require "snax.gateserver"
local crypt = require "skynet.crypt"
local socketdriver = require "skynet.socketdriver"
local log = require "chestnut.skynet.log"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

--[[

Protocol:

	All the number type is big-endian

	Shakehands (The first package)

	Client -> Server :

	base64(uid)@base64(server)#base64(subid):index:base64(hmac)

	Server -> Client

	XXX ErrorCode
		404 User Not Found
		403 Index Expired
		401 Unauthorized
		400 Bad Request
		200 OK

	Req-Resp

	Client -> Server : Request
		word size (Not include self)
		string content (size-4)
		dword session
		byte tag ('R') (0 & (1 << 2) & (1 << 4))

	Server -> Client : Response
		word size (Not include self)
		string content (size-5)
		-- byte ok (1 is ok, 0 is error)
		dword session
		byte tag ('Q') (0 & (1 << 2) & (0 << 4))

	Server -> Client : Request
		word size (Not include self)
		string content (size-5)
		dword session (4)
		byte tag ('R') (0 & (0 << 2) & (1 << 4))

	Client -> Server : Response
		word size (Not include self)
		string content (size-5)
		-- byte ok (1)
		dword session (4)
		byte tag ('Q') (0 & (0 << 2) & (0 << 4))

API:
	server.userid(username)
		return uid, subid, server

	server.username(uid, subid, server)
		return username

	server.login(username, secret)
		update user secret

	server.logout(username)
		user logout

	server.ip(username)
		return ip when connection establish, or nil

	server.start(conf)
		start server

Supported skynet command:
	kick username (may used by loginserver)
	login username secret  (used by loginserver)
	logout username (used by agent)

Config for server.start:
	conf.expired_number : the number of the response message cached after sending out (default is 128)
	conf.login_handler(uid, secret) -> subid : the function when a new user login, alloc a subid for it. (may call by login server)
	conf.logout_handler(uid, subid) : the functon when a user logout. (may call by agent)
	conf.kick_handler(uid, subid) : the functon when a user logout. (may call by login server)
	conf.request_handler(username, session, msg) : the function when recv a new request.
	conf.register_handler(servername) : call when gate open
	conf.disconnect_handler(username) : call when a connection disconnect (afk)
]]

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}
local handshake   = {}
local connection  = {}

local function unforward(c)
	if c.agent then
		forwarding[c.agent] = nil
		c.agent = nil
		c.client = nil
	end
end

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
		request = {}
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.forward(source, fd, client, address, ... )
	-- body
	local c = assert(connection[fd])
	unforward(c)
	c.client = client or 0
	c.agent = address or source
	forwarding[c.agent] = c
end

function server.unforward(source, fd)
	-- body
	local c = assert(connection[fd])
	if c.agent then
		forwarding[c.agent] = nil
		c.agent = nil
		c.client = nil
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	-- called by agent
	local handler = {}

	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
	}

	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(source, ...)
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

	function handler.connect(fd, addr)
		skynet.error("connect " .. addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username, fd)
			end
		end
	end

	handler.error = handler.disconnect

	local function do_start(fd, ... )
		-- body
		assert(fd)
		local u = assert(connection[fd], "invalid fd")
		local start_handler = assert(conf.start_handler)
		start_handler(u.username, fd)
	end

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		log.info(message)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		log.info("username: %s, index:%s, hmac:%s", username, index, hmac)
		local u = user_online[username]
		if u == nil then
			log.info("404 User Not Found")
			return "404 User Not Found"
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			log.info("403 Index Expired")
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac_hash(u.secret, text)	-- equivalent to crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			log.info("401 Unauthorized")
			return "401 Unauthorized"
		end

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end

		local close = result ~= nil

		if result == nil then
			result = "200 OK"
		end

		socketdriver.send(fd, netpack.pack(result))

		if close then
			log.info("close")
			gateserver.closeclient(fd)
		else
			log.info("do_start")
			do_start(fd)	
		end
	end

	local request_handler = assert(conf.request_handler)

	-- u.response is a struct { return_fd , response, version, index }
	local function retire_response(u)
		if u.index >= expired_number * 2 then
			local max = 0
			local response = u.response
			for k,p in pairs(response) do
				if p[1] == nil then
					-- request complete, check expired
					if p[4] < expired_number then
						response[k] = nil
					else
						p[4] = p[4] - expired_number
						if p[4] > max then
							max = p[4]
						end
					end
				end
			end
			u.index = max + 1
		end
	end

	local function do_request(fd, message)
		local u = assert(connection[fd], "invalid fd")
		print(#message) 
		if #message == 0 then
			socketdriver.send(fd, string.pack(">s2", ""))
			return 		
		end 			
		local len = #message
		local tag = string.unpack("B", string.sub(message, len))
		local session = string.unpack(">I4", string.sub(message, len-4, len-1))
		message = string.sub(message, 1, len-5)
		print("tag is", tag, "session is", session, "size of msg is", #message)
		if tag == c2s_req_tag then
			local p = u.response[session]
			if p then 	
				-- session can be reuse in the same connection
				if p[3] == u.version then
					local last = u.response[session]
					u.response[session] = nil
					p = nil
					if last[2] == nil then
						local error_msg = string.format("Conflict session %s", crypt.hexencode(session))
						skynet.error(error_msg)
						error(error_msg)
					end 
				end 	
			end 		

			if p == nil then
				-- new pack
				p = { fd }
				u.response[session] = p
				print("************************abced1")
				local ok, result = pcall(conf.request_handler, u.username, message)
				print("***********abced2", ok, "lenght of result is", #result)
				-- NOTICE: YIELD here, socket may close.
				result = result or ""
				if not ok then
					skynet.error(result)
					result = string.pack(">I4B", session, c2s_resp_tag)
				else
					result = result .. string.pack(">I4B", session, c2s_resp_tag)
				end

				p[2] = string.pack(">s2",result)
				p[3] = u.version
				p[4] = u.index
			else
				-- update version/index, change return fd.
				-- resend response.
				p[1] = fd
				p[3] = u.version
				p[4] = u.index
				if p[2] == nil then
					-- already request, but response is not ready
					return
				end
			end
			u.index = u.index + 1
			-- the return fd is p[1] (fd may change by multi request) check connect
			fd = p[1]
			if connection[fd] then
				socketdriver.send(fd, p[2])
			end
			p[1] = nil
			retire_response(u)
		else
			assert(tag == s2c_resp_tag)
			conf.response_handler(u.username, message)
		end
	end

	local function request(fd, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	local function do_msg(fd, msg, sz, ... )
		-- body
		local u = assert(connection[fd], "invalid fd")
		local msg_handler = assert(conf.msg_handler)
		msg_handler(u.username, msg, sz)
	end

	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			skynet.error("gateserver start auth ...")
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
			skynet.error("gateserver close auth ...")
		else
			-- request(fd, msg, sz)
			do_msg(fd, msg, sz)
		end
	end

	return gateserver.start(handler)
end

return server
