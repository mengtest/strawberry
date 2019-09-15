local skynet = require "skynet"
local address
local _M = {}

local function get_address()
    if not address then
        address = skynet.uniqservice "chestnut/chat_mgr"
    end
    return address
end

function _M.say(args)
    skynet.send(get_address(), "client", args)
end

return _M
