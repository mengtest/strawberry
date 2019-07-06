local skyent = require 'skynet'
local service = require 'service'
local util = require 'db.util'
local lfs = require 'lfs'
local log = require "chestnut.skynet.log"

local function init()
    local db = util.connect_mysql()
    local fd = io.open('./config/mysql/update_db.sql')
    local sql = fd:read('a')
    db:query(sql)
    util.disconnect_mysql(db)
end

local CMD = {}

function CMD.initdb()
    local ok, err = pcall(init)
    if ok then
        return true
    end
    log.error(err)
    return false
end

service.init {
    command = CMD
}
