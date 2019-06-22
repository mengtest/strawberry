local skynet = require "skynet"
local log = require "chestnut.skynet.log"

local context = require "chestnut.agent.AgentContext"
local REQUEST = require "chestnut.agent.request"
local RESPONSE = require "chestnut.agent.response"

local traceback = debug.traceback
local assert = assert
local login_type = skynet.getenv 'login_type'
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
mod.command = context
service.init(mod)

