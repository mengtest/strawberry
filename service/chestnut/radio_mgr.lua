local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local service = require("service")

local users = {}
local board = "weixinhao:nihao"
local adver = "weixinhao:nihao"
local NORET = {}

local CMD = {}

function CMD.start( ... )
	-- body
	return true
end

function CMD.init_data()
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

function CMD.checkin(uid, agent, ... )
	-- body
	assert(users[uid] == nil)
	users[uid] = { uid = uid, agent = agent }
end

function CMD.afk(uid)
	-- body
	assert(users[uid])
	users[uid] = nil
end

function CMD.board()
	-- body
	local res = {}
	res.errorcode = 0
	res.text = board
	return res
end

function CMD.adver()
	-- body
	local res = {}
	res.errorcode = 0
	res.text = adver
	return res
end

function CMD.radio(type, text, ... )
	-- body
	if type == 1 then
		board = text
		local args = {}
		args.text = text
		for _,v in pairs(users) do
			skynet.send(v.agent, "lua", "board", args)
		end
	elseif type == 2 then
		adver = text
		local args = {}
		args.text = text
		for _,v in pairs(users) do
			skynet.send(v.agent, "lua", "adver", args)
		end
	end
end

service.init {
	name = '.RADIO_MGR',
	command = CMD
}
