local skynet = require "skynet"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
local redis = require "chestnut.redis"
local json = require "rapidjson"
local service = require "service"
local savedata = require "savedata"
local assert = assert

local refreshs = {}
local channel


local function save_data()
end

local function save_data_loop()
	while true do
		skynet.sleep(100 * 10)
		channel:publish('save_data')
	end
end

local CMD = {}

function CMD.get_channel_id( ... )
	-- body
	return channel.channel
end

service.init {
	name = '.REFRESH_MGR',
	init = function ()
		channel = mc.new()
		skynet.fork(save_data_loop)
	end,
	command = CMD
}
