-- if client for this node has 
local skynet = require "skynet"
local server = require 'server'
local service = require 'service'

local CMD = {}

function CMD.query_service(service_name)
	assert(service_name)
    return server.host.query_service(service_name)
end

service.init {
    name = '.serverd',
	init = function ()
	end,
	command = CMD
}