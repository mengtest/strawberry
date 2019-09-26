local skynet = require "skynet"
local client = require "client"
local service = require "service"
local command = require "cmd"
require "chestnut.agent.context"
require "chestnut.agent.request"
require "chestnut.agent.response"
local traceback = debug.traceback
local assert = assert

local client_mod = {}
client.init(client_mod)

local mod = {}
mod.require = {}
mod.init = function()
end
mod.command = command
service.init(mod)
