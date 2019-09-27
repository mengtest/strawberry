local skynet = require "skynet"
local context = require "chestnut.bag.context"
local CMD = {}

function CMD.get_item(uid, id)
	return context.get_item(uid, id)
end

function CMD.consume(uid, id, num)
	return context.consume(uid, id, num)
end

function CMD.reward(uid, id, num)
end

return CMD
