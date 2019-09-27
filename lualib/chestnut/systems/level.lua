local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local sd = require "skynet.sharetable"
local _M = {}
local level_config

local function on_level_up()
end

skynet.init(
	function()
		level_config = sd.query("levelConfig")
	end
)

function _M.on_enter(self)
end

function _M.on_exit(self)
end

function _M.add_exp(self, exp)
	-- body
	assert(self)
	assert(exp > 0)
	self.mod_user.exp = self.mod_user.exp + exp
	-- local level = self.mod_user.exp / level_config
end

return _M
