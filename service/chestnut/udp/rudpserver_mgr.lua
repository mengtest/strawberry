local skynet = require "skynet"
require "skynet.manager"
local queue = require "chestnut.queue"
local service = require "service"

local gate_max = 10
local pool = queue()
local S = {}
local SESSION = 0

local CMD = {}

function CMD.start( ... )
	-- body
	local udpgated = skynet.getenv("udpgated")
	local host, port = string.match(udpgated, "([%d.]+)%:(%d+)")
	q = queue()
	for i=1,gate_max do
		local xport = port + i
		local udpgate = skynet.newservice("rudpserver")
		skynet.call(udpgate, "lua", "start", host, xport)
		q:enqueue(udpgate)
	end
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

function CMD.register(service, key)

	SESSION = (SESSION + 1) & 0xffffffff
	S[SESSION] = {
		session = SESSION,
		key = key,
		room = snax.bind(service, "room"),
		address = nil,
		time = skynet.now(),
		lastevent = nil,
	}
	return SESSION
end

function CMD.unregister(session)
	S[session] = nil
end

function CMD.enter(uid, addr, ... )
	-- body
	local udpgate = q:dequeue()
	local res = skynet.call(udpgate, "lua", "register", addr, uid)
	res.gate = udpgate
	res.uid = uid
	q:enqueue(udpgate)
	return res
end

service.init {
	name = '.UDPSERVER_MGR',
	command = CMD
}
