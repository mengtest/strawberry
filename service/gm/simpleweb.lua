local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local log = require "chestnut.skynet.log"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local route = require "gm.web.route"
local errorcode = require "gm.web.errorcode"

local pcall = skynet.pcall
local assert = assert
local table = table
local string = string

local mode = ...

if mode == "agent" then

local sessions = {}
local session = 1
local CMD = {}

function CMD.accept(id, ... )
	-- body
	socket.start(id)
	
	log.info("accept")
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	-- log.info(url)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			route.route(id, code, url, method, header, body)				
		end
	else
		if url == sockethelper.socket_error then
			skynet.error("socket closed")
		else
			skynet.error(url)
		end
	end
	socket.close(id)
	log.info("close")

end

function CMD.register(agent, ... )
	-- body
	session = session + 1
	if session > 100000000 then
		session = 1
	end
	local u = {}
	u.session = session
	u.agent = source
	sessions[session] = u
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = CMD[cmd]
		local r = f( ... )
		if r ~= errorcode.NORET then
			skynet.ret(skynet.pack(r))
		end
	end)
end)

else

skynet.start(function()
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8181)
	skynet.error("Listen web port 8181")
	socket.start(id , function(id, addr)
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", "accept", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
