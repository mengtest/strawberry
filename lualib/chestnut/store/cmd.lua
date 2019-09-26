local skynet = require "skynet"
local savedata = require "savedata"
local command = require "command"
local CMD = require "cmd"

function CMD.start()
    -- savedata.init {}
    -- savedata.subscribe()
    return true
end

function CMD.init_data()
    return true
end

function CMD.sayhi()
    return true
end

function CMD.save_data()
end

function CMD.close()
    return true
end

function CMD.kill()
    skynet.exit()
end

function CMD.fetch_store_items(uid, args)
end

return CMD
