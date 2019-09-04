local client = require "client"
local CMD = require("chestnut.agent.cmd")
local REQUEST = client.request()

local _M = {}

function _M:on_data_init(db_data)
	-- body
	local data = db_data.db_user_achievements
	self.mod_achievement = {}
	self.mod_achievement.achieves = {}
	if data ~= nil then
		for k, v in pairs(data) do
			local item = {}
			item.id = v.id
			item.reach = v.reach
			item.recv = v.recv
			item.create_at = v.create_at
			item.update_at = v.update_at
			self.mod_achievement.achieves[item.id] = item
		end
	end
end

function _M:on_data_save(db_data)
	-- body
	db_data.db_user_achievements = {}
	local data = self.mod_achievement.achieves
	for k, v in pairs(data) do
		local item = {}
		item.uid = self.uid
		item.id = v.id
		item.reach = v.reach
		item.recv = v.recv
		item.create_at = v.create_at
		item.update_at = v.update_at
		table.insert(db_data.db_user_achievements, item)
	end
end

function _M:on_enter()
	-- client.push(self, '')
end

return _M
