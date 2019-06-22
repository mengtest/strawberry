local skynet = require "skynet"
local service = require "service"
local host = require "xlog.host"

local TI

local function co() 
    while true do 
        skynet.sleep(100 * 2)
        host.flush(TI)
    end
end

local CMD = {}

function CMD.start()
	-- body
	skynet.fork(co)
	return true
end

function CMD.init_data()
	return true
end

function CMD.sayhi()
	-- body
	-- 初始化各种全服信息
	return true
end

function CMD.close( ... )
	-- body
	save_data()
	return true
end

function CMD.kill( ... )
	-- body
	skynet.exit()
end

skynet.

service.init {
    init = function ( ... )
        -- body
        local dir = skynet.getenv('xlogpath')
        local rollsz = skynet.getenv('xlogroll')
        TI = host.alloc(dir, rollsz)
    end,
	command = CMD
}