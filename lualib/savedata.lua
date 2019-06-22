local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local mc = require "skynet.multicast"
local traceback = debug.traceback

local address
local channel
local inited = false
local subscribed = false

local service = {}

function service.init(mod)
    address = skynet.uniqueservice("chestnut/refresh_mgr")
    local channel_id = skynet.call(address, 'lua', 'get_channel_id')

    local funcs = mod.command
    channel = mc.new {
		channel = channel_id,
		dispatch = function (_, _, cmd, ...)
            -- body
            local f = assert(funcs[cmd])
            local ok, err = xpcall(f, traceback, ...)
            if not ok then
                log.error(" sub [%s] error = [%s]", cmd, err)
            end
		end
    }
    inited = true
end

function service.subscribe()
    if inited and not subscribed then
        channel:subscribe()
        subscribed = true
    end
end

function service.unsubscribe()
    channel:unsubscribe()
end

return service
