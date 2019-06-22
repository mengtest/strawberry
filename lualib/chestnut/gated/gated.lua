local msgserver = require "chestnut.gated.msgserver"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"

local loginservice = ".LOGIND"
local servername


local server = {}
local users = {}
local username_map = {}
local internal_id = 0
local forwarding  = {}	-- agent -> connection

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(source, uid, secret, ...)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local username = msgserver.username(uid, id, servername)
	log.info("gated username: %s, uid: %s", username, uid)

	-- you can use a pool to alloc new agent
	-- local agent = skynet.newservice "agent"
	
	local agent = skynet.call(".AGENT_MGR", "lua", "enter", uid)
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = id,
		online = false,
	}

	-- trash subid (no used)
	local err = skynet.call(agent, "lua", "login", skynet.self(), uid, id, secret)
	if err == servicecode.SUCCESS then
		log.info("gated call login err = %d", err)
		users[uid] = u
		username_map[username] = u
		msgserver.login(username, secret)

		-- you should return unique subid
		local res = {}
		res.errorcode = err
		res.subid = id
		return res
	else
		log.info("gated call login err = %d", err)
		local res = {}
		res.errorcode = err
		res.subid = 0
		return res
	end
end

-- call by agent
function server.logout_handler(source, uid, subid)
	local u = users[uid]
	if u then
		log.info("call loginservice logout")
		local err = skynet.call(loginservice, "lua", "logout", uid, subid)
		if err ~= servicecode.SUCCESS then
			log.error("logind service logout failture.")
		else
			log.info("logind service logout ok.")
		end
		return err
	else
		log.error("gated service not contains uid(%d)", uid)
		return servicecode.FAIL
	end
end

-- call by login server
function server.kick_handler(source, uid, subid)
	local u = users[uid]
	if u then
		if not u.online then
			log.info("uid(%d) not authed.", uid)
		end
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		-- pcall(skynet.call, u.agent.handle, "lua", "logout")
		log.info("uid(%d) kick agent, call agent logout", uid)
		local err = skynet.call(u.agent, "lua", "logout", uid)
		if err == servicecode.SUCCESS then
			msgserver.logout(u.username)
			users[uid] = nil
			username_map[u.username] = nil
		else
			log.error("gated pcall agent kick error.")
		end
		return err
	else
		log.error("uid = %d not existence.")
		return false
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username, fd)
	local u = username_map[username]
	if u then
		if u.online then
			log.info("call uid(%d) afk", u.uid)
			skynet.call(u.agent, "lua", "afk", fd)
		else
			log.error('disconnet when onlien is false')
		end
	end
end

-- call by self
function server.start_handler(username, fd, ... )
	-- body
	local u = username_map[username]
	if u then
		if u.online == nil or u.online == false then
			local agent = assert(u.agent)
			local conf = {
				uid = u.uid,
				client = fd,
			}
			log.info("start_handler")
			skynet.call(agent, "lua", "auth", conf)
			u.online = true
			u.fd = fd
		else
			log.error('online is true, start auth ...')
		end
	end
end

-- call by self
function server.msg_handler(username, msg, sz,... )
	-- body
	local u = username_map[username]
	if u then
		if u.online then
			log.info('TEST MSG')
			local agent = assert(u.agent)
			skynet.redirect(agent, skynet.self(), "client", u.fd, msg, sz)
		end
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	local u = username_map[username]
	return skynet.tostring(skynet.rawcall(u.agent, "client", msg))
end

-- call by self (when gate open)
function server.register_handler(name)
	skynet.error(string.format("reister gate server: %s", name))
	servername = name
	local gated = skynet.getenv "gated"
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self(), gated)
	skynet.error('gatea')
end

msgserver.start(server)

