local skynet = require "skynet"
local savedata = require "savedata"
local context = require "chestnut.store.context"
local dbc = require "db"
local CMD = require "cmd"

function CMD.start()
    -- savedata.init {}
    -- savedata.subscribe()
    return true
end

function CMD.init_data()
    -- context.on_data_init(db_data)
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
    return context.fetch_store_items(uid, args)
end

function CMD.fetch_store_item(uid, args)
    return context.fetch_store_item(uid, args)
end

function CMD.buy_store_item(uid, args)
    return context.buy_store_item(uid, args)
end

return CMD
