local skynet = require 'skynet'
local log = require "chestnut.skynet.log"
local client = require 'client'

local function init_user(mod)
	local sex      = 1
	local nickname = "hell"
	local province = 'Beijing'
	local city     = "Beijing"
	local country  = "CN"
	local headimg  = "xx"
	mod.sex = sex
	mod.nickname = nickname
	mod.province = province
	mod.city = city
	mod.country = country
	mod.headimg = headimg
	mod.openid = 1
	mod.nameid = 1
	mod.create_at = os.time()
	mod.update_at = os.time()
	mod.login_at = os.time()
	mod.new_user = 1
	mod.level = 1
end

local _M = {}

function _M:on_data_init(db_data)
	local data = db_data.db_users[1]
	self.mod_user = {}
	if data == nil then
		init_user(self.mod_user)
	else
		self.mod_user.sex = data.sex
		self.mod_user.nickname = data.nickname
		self.mod_user.province = data.province
		self.mod_user.city = data.city
		self.mod_user.country = data.country
		self.mod_user.headimg = data.headimg
		self.mod_user.openid = data.openid
		self.mod_user.nameid = data.nameid
		self.mod_user.create_at = data.create_at
		self.mod_user.update_at = data.update_at
		self.mod_user.login_at = os.time()
		self.mod_user.new_user = data.new_user
		self.mod_user.level = data.level
	end
end

function _M:on_data_save(db_data)
	db_data.db_user = {}
	db_data.db_user.uid = self.uid
	db_data.db_user.sex = self.mod_user.sex
	db_data.db_user.nickname = self.mod_user.nickname
	db_data.db_user.province = self.mod_user.province
	db_data.db_user.city = self.mod_user.city
	db_data.db_user.country = self.mod_user.country
	db_data.db_user.heading = self.mod_user.heading
	db_data.db_user.openid = self.mod_user.openid
	db_data.db_user.nameid = self.mod_user.nameid
	db_data.db_user.create_at = self.mod_user.create_at
	db_data.db_user.update_at = os.time()
	db_data.db_user.login_at = self.mod_user.login_at
	db_data.db_user.new_user = self.mod_user.new_user
	db_data.db_user.level = self.mod_user.level
end

function _M:on_enter()
	-- body
	local pack = {
		num      = 0,
        nickname = self.mod_user.nickname,
		nameid   = self.mod_user.nameid,
        rcard    = 0
	}
	client.push(self, 'base_info', pack)
end

function _M:on_exit()
end

return _M