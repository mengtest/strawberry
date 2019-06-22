local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local snax = require "snax"
local kcp = require "kcp"
local log = require "chestnut.skynet.log"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local CMD = {}
local HOST, PORT
local U
local K
local timeout = 10 * 60 * 100	-- 10 mins
local SESSION = 0
local KEY
local ROOM
local address
local host
local send_request

--[[
	8 bytes hmac   crypt.hmac_hash(key, session .. data)
	4 bytes localtime
	4 bytes eventtime		-- if event time is ff ff ff ff , time sync
	4 bytes session
	padding data
]]


local function request(name, args, response)
	log.info("client request [%s]", name)
	local result = skynet.call(ROOM, "lua", name, SESSION, args)
	if result then
		return response(result)
	else
		log.error("client request [%s] result is nil", name)
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

local function sprotodispatch(_, _, type, ...)
	-- body
	if type == "REQUEST" then
		local traceback = debug.traceback
		local ok, result = xpcall(request, traceback, ...)
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



local function timesync(session, localtime, from)
	-- return globaltime .. localtime .. eventtime .. session , eventtime = 0xffffffff
	local now = skynet.now()
	if K then
		K:input(string.pack("<IIII", now, localtime, 0xffffffff, session))
	else
		log.error('K is invalid')
	end
	-- socket.sendto(U, from, string.pack("<IIII", now, localtime, 0xffffffff, session))
end

local function dispatch(str, from)
	local localtime, eventtime, session = string.unpack("<III", str, 9)
	local s = S[session]
	if s then
		if s.address ~= from then
			if crypt.hmac_hash(s.key, str:sub(9)) ~= str:sub(1,8) then
				snax.printf("Invalid signature of session %d from %s", session, socket.udp_address(from))
				return
			end
			s.address = from
		end
		if eventtime == 0xffffffff then
			return timesync(session, localtime, from)
		end
		s.time = skynet.now()
		-- NOTICE: after 497 days, the time will rewind
		if s.time > eventtime + timeout then
			snax.printf("The package is delay %f sec", (s.time - eventtime)/100)
			return
		elseif eventtime > s.time then
			-- drop this package, and force time sync
			return timesync(session, localtime, from)
		elseif s.lastevent and eventtime < s.lastevent then
			-- drop older event
			return
		end
		s.lastevent = eventtime
		-- s.room.post.update(str:sub(9))
		sprotodispatch(host:dispatch(str:sub(9)))
		-- skynet.send(ROOM, 'lua', )
	else
		snax.printf("Invalid session %d from %s" , session, socket.udp_address(from))
	end
end

local function keepalive()
	-- trash session after no package last 10 mins (timeout)
	while true do
		-- local i = 0
		-- local ti = skynet.now()
		-- for session, s in pairs(S) do
		-- 	i=i+1
		-- 	if i > 100 then
		-- 		skynet.sleep(3000)	-- 30s
		-- 		ti = skynet.now()
		-- 		i = 1
		-- 	end
		-- 	if ti > s.time + timeout then
		-- 		S[session] = nil
		-- 	end
		-- end
		K:update()
		local str = K:recv()
		if str then
			dispatch(str, address)
		end
		skynet.sleep(6000)	-- 1 min
	end
end

local function udpdispatch(str, from)
	-- body
	if K then
		address = from
		K:input(str)
	else
		log.error('K is invalid')
	end
end

local function kcpsend(str)
	-- body
	if K then
		socket.sendto(U, address, str)
	else
		log.error("Session is invalid %d")
	end
end

-- 服务协议
function CMD.start(host, port)
	-- body
	HOST = host
	PORT = port
	U = socket.udp(udpdispatch, host, port)
	K = kcp(kcpsend)
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(keepalive)
	return true
end

function CMD.init_data( ... )
	-- body
	return true
end

function CMD.sayhi( ... )
	-- body
	return true
end

function CMD.close( ... )
	-- body
	return true
end

function CMD.kill( ... )
	-- body
	skynet.exit()
end

-- 交流
function CMD.register(session, key, room)
	SESSION = session
	KEY = key
	ROOM = room
	return true
end

function CMD.unregister(session)
	return true
end

function CMD.post(session, data)
	assert(session == SESSION)
	if K then
		K:send(data)
	else
		log.error('K is invalid')
	end
end

function CMD.clear( ... )
	-- body
	address = 0
end

skynet.start(function ( ... )
	-- body
	skynet.dispatch("lua", function(_,_, cmd, subcmd, ...)
		local f = CMD[cmd]
		local r = f(subcmd, ... )
		if r ~= nil then
			skynet.ret(skynet.pack(r))
		end
	end)
end)

