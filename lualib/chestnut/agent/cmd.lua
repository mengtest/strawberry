local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local servicecode = require "enum.servicecode"
local context = require "chestnut.agent.context"
local savedata = require "savedata"
local CMD = require "cmd"
local SUB = {}
local traceback = debug.traceback

function SUB.save_data()
    context.save_data()
end

function CMD.start()
    savedata.init(
        {
            command = SUB
        }
    )
    return true
end

function CMD.init_data()
    return true
end

function CMD.sayhi(reload)
    -- 重连的时候，auth函数用此判断
    _reload = reload
    return true
end

function CMD.close()
    return true
end

function CMD.kill()
end

function CMD.login(gate, uid, subid, secret)
    return context.login(gate, uid, subid, secret)
end

-- call by gated
function CMD.logout(uid)
    return context.logout(uid)
end

-- call by agent mgr
function CMD.kill_cache(uid)
    return context.kill_cache(uid)
end

function CMD.auth(args)
    return context.auth(args)
end

function _M.afk(fd)
    return context.afk(fd)
end

return CMD
