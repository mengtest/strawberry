local skynet = require "skynet"

local address

local function get_address()
    if not address then
        address = skynet.uniqservice 'db'
    end
    return address
end

local _M = {}

function _M.call_read_sysmail( ... )
    -- body
    local handle = get_address()
    return skynet.call(handle, 'read_sysmail', ...)
end

function _M.call_read_account_by_username()
    local handle = get_address()
    return skynet.call(handle, 'read_account_by_username', ...)
end

return _M