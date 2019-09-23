local skynet = require "skynet"
local sd = require "skynet.sharedata"
local snowflake = require "chestnut.snowflake"
local log = require "chestnut.skynet.log"
local zset = require "chestnut.zset"
local sysmaild = require "sysmaild"
local client = require "client"
local _M = {}
local roomid = 0
local users = {} -- 在线用户
local rooms = {} -- 房间聊天

skynet.init(
	function()
	end
)

function _M.init()
	local room = {id = roomid}
	rooms[room.id] = room
end

function _M.on_data_init(dbData)
	assert(dbData ~= nil)
	assert(dbData.db_users ~= nil)
	assert(#dbData.db_users == 1)

	return true
end

function _M.on_data_save(dbData)
	assert(dbData ~= nil)
	return true
end

function _M.on_enter()
end

function _M.login(u)
	users[u.uid] = u
end

function _M.afk(uid)
	assert(users[uid])
	users[uid] = nil
end

function _M.say(from, to, word)
	if rooms[to] then
		local room = rooms[to]
		for _, v in pairs(room) do
			if users[v] then
				skynet.send(users[v].agent, "lua", "say", from, word)
			end
		end
	elseif users[to] then
		skynet.send(users[to].agent, "lua", "say", from, word)
	end
end

return _M
