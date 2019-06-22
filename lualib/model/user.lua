
local DATA = {}

local _M = {}

_M.dataset = DATA

function _M.load(dbData, ... )
    -- body
    -- body
	assert(dbData ~= nil)
	assert(dbData.db_users ~= nil)
	assert(#dbData.db_users == 1)

	-- user
	local seg = dbData.db_users[1]
	self.dbUser.sex        = assert(seg.sex)
	self.dbUser.nickname   = assert(seg.nickname)
	self.dbUser.province   = assert(seg.province)
	self.dbUser.city       = assert(seg.city)
	self.dbUser.country    = seg.country
	self.dbUser.headimg    = seg.headimg
	self.dbUser.openid     = seg.openid
	self.dbUser.nameid     = seg.nameid
	self.dbUser.createAt   = seg.create_at
	self.dbUser.updateAt   = assert(seg.update_at)
	self.dbUser.loginAt    = assert(seg.login_at)
	self.dbUser.newUser    = assert(seg.new_user)
	self.dbUser.level      = assert(seg.level)
	self.dbUser.exp = 0
	return true
end

function _M.save(dbData)
    -- body
	assert(dbData ~= nil)

	-- save user
	dbData.db_user = {}
	dbData.db_user.uid            = self.agentContext.uid
	dbData.db_user.sex            = self.dbUser.sex
	dbData.db_user.nickname       = self.dbUser.nickname
	dbData.db_user.province       = self.dbUser.province
	dbData.db_user.city           = self.dbUser.city
	dbData.db_user.country        = self.dbUser.country
	dbData.db_user.headimg        = self.dbUser.headimg
	dbData.db_user.openid         = self.dbUser.openid
	dbData.db_user.nameid         = self.dbUser.nameid
	dbData.db_user.create_at      = self.dbUser.createAt
	dbData.db_user.update_at 	  = self.dbUser.updateAt
	dbData.db_user.login_at       = self.dbUser.loginAt
	dbData.db_user.new_user       = self.dbUser.newUser
	dbData.db_user.level          = self.dbUser.level
	return true
end

return _M