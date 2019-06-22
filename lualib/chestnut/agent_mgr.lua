local skynet = require "skynet"
local assert = assert

local address

local function get_address()
    if not address then
        address = skynet.uniqservice 'chestnut/agent_mgr'
    end
    return address
end

local _M = {}

function _M.call_enter( ... )
    -- body
    local handle = get_address()
    assert(handle)
    return skynet.call(handle, 'enter', ...)
end

return _M