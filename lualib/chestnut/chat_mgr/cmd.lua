local skynet = require "skynet"
local service = require "service"
local log = require "chestnut.skynet.log"
local context = require "chestnut.chat_mgr.context"
local traceback = debug.traceback
local assert = assert
local CMD = {}

function CMD.start()
	context.init()
	return true
end

function CMD.init_data()
	-- context.on_data_init()
	return true
end

function CMD.sayhi()
	return true
end

function CMD.close()
	return true
end

function CMD.kill()
	skynet.exit()
end

------------------------------------------
-- 签到
function CMD.login(uid, agent)
	local u = {
		uid = uid,
		agent = agent
	}
	context.login(u)
end

function CMD.afk(uid)
	context.afk(uid)
end

function CMD.say(from, word)
end

return CMD
