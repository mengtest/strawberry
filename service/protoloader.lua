-- module proto as examples/proto.lua

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
-- local proto = require "proto"

skynet.start(function()

	local c2s_filename = "./proto/c2s.sproto"
	local s2c_filename = "./proto/s2c.sproto"

	sprotoloader.register(c2s_filename, 1)
	sprotoloader.register(s2c_filename, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
