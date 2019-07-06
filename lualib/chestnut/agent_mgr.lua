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

function _M.enter(uid)
    -- body
    local handle = get_address()
    assert(handle)
    return skynet.call(handle, 'enter', uid)
end

function _M.exit(uid)
    local handle = get_address()
    assert(handle)
    return skynet.call(handle, 'exit', uid)
end

function _M.exit_at_once(uid)
    local handle = get_address()
    assert(handle)
    return skynet.call(handle, 'exit_at_once', uid)
end

return _M