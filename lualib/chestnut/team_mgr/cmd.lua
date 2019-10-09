local skynet = require "skynet"
local savedata = require "savedata"
local context = require "chestnut.team_mgr.context"
local CMD = require "cmd"
local SUB = {}

function SUB.save_data()
	context.save_data()
end

function CMD.start()
	savedata.init {
		command = SUB
	}
	savedata.subscribe()
	return true
end

function CMD.init_data()
	return context.init_data()
end

function CMD.sayhi()
	return true
end

function CMD.close()
	context.save_data()
	return true
end

function CMD.kill()
	skynet.exit()
end

------------------------------------------
-- gameplay协议
function CMD.fetch_teams(uid, args)
	return context.fetch_teams(uid, args)
end

function CMD.fetch_team(uid, args)
	return context.fetch_team(uid, args)
end

function CMD.create_team(uid, args)
	return context.create_team(uid, args)
end

function CMD.join_team(uid, args)
	return context.join_team(uid, args)
end

function CMD.fetch_myteams(uid, args)
	return context.fetch_myteams(uid, args)
end

function CMD.quit_team(uid, args)
	return context.quit_team(uid, args)
end

return CMD
