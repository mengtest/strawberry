local skynet = require "skynet"
local context = require "chestnut.bag.context"
local CMD = {}

function CMD.get_item(uid, id)
	return context.get_item(uid, id)
end

return CMD
