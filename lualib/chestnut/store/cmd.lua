local skynet = require "skynet"
local savedata = require "savedata"
local context = require "chestnut.store.context"
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

function CMD.fetch_store_items(uid, args)
    return context.fetch_store_items(uid, args)
end

function CMD.fetch_store_item(uid, args)
    return context.fetch_store_item(uid, args)
end

function CMD.buy_store_item(uid, args)
    return context.buy_store_item(uid, args)
end

return CMD
