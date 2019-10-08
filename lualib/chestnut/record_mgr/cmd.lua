local skynet = require "skynet"
local context = require "chestnut.record_mgr.context"
local CMD = require "cmd"
local SUB = {}

function SUB.save_data()
    context.save_data()
end

function CMD.start()
    savedata.init {
        command = SUB
    }
    savedata.subscribe()
    return true
end

function CMD.init_data()
    return context.init_data()
end

function CMD.sayhi()
    return true
end

function CMD.close()
    context.save_data()
    return true
end

function CMD.kill()
    skynet.exit()
end

function CMD.fetch_record(uid, id)
end

return CMD
