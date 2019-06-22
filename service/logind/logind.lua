local login = require "snax.loginserver"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"

local address, port = string.match(skynet.getenv("logind"), "([%d.]+)%:(%d+)")
local logind_name = skynet.getenv "logind_name"
local signupd_name = skynet.getenv "signupd_name"
local server = {
	host = address or "127.0.0.1",
	port = tonumber(port) or 8002,
	multilogin = false,	-- disallow multilogin
	name = logind_name,
	instance = 8,
}

local server_list = {}
local user_online = {}
local user_login = {}

function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	assert(password == "Password", "Invalid password")
	log.info("auth_handler %s@%s:%s", user, server, password)
	local res = skynet.call("." .. signupd_name, "lua", "signup", server, user, password)
	if res.code == 200 then
		return server, res.uid
	else
		log.error("signup server return code is not 200.")
		error("signup error.")
	end
end

function server.login_handler(server, uid, secret)
	log.info(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		-- log.info("uid(%d) logined again, will kick last address(%d), begin ---------- ", uid, last.address)
		-- local ok = skynet.call(last.address, "lua", "kick", uid, last.subid)
		-- if not ok then
		-- 	log.error("kick uid(%d) failture, so you can not login.", uid)
		-- 	error(string.format("kick uid(%d) failture", uid))
		-- else
		-- 	log.info("uid(%d) logined again, last address has logout, end ---------- ", uid)
		-- end
		error(string.format("uid(%d) already online", uid))
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end
	
	local res = skynet.call(gameserver.address, "lua", "login", uid, secret)
	if res.errorcode == servicecode.SUCCESS then 
		user_online[uid] = { address = gameserver.address, subid = res.subid , server = server}
		local gated = gameserver.gated

		local key = string.format("%s#%d@%s", uid, res.subid, gated)
		return key
	elseif res.errorcode == servicecode.LOGIN_AGENT_LOAD_ERR then
		log.error("LOGIN_AGENT_LOAD_ERR.")
		error("LOGIN_AGENT_LOAD_ERR")
	else
		error("gen subid is wrong")
	end
end

local CMD = {}

function CMD.register_gate(server, address, gated)
	local s = {
		address = address,
		gated = gated,
	}
	server_list[server] = s
	return true
end

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		log.info(string.format("%s@%s is logout", uid, u.server))
		local err = skynet.call(u.address, 'lua', 'kick', uid, subid)
		if err == servicecode.SUCCESS then
			user_online[uid] = nil
		end
		return err
	else
		log.error("logined service logout failture, uid: %d, subid: %d", uid, subid)
		return servicecode.FAIL
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
