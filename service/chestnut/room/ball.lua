local skynet = require "skynet"
require "skynet.manager"
local crypt = require "skynet.crypt"
local log = require "chestnut.skynet.log"

local context = require "chestnut.ballroom.context"
local CMD = require "chestnut.ballroom.cmd"


local client = require("client")
local service = require("service")


local client_mod = {}
client_mod.request = REQUEST
client_mod.response = RESPONSE

client.init(client_mod)

local mod = {}
mod.require = {}
mod.init = function ( ... )
	-- body
end
mod.command = CMD
service.init(mod)
