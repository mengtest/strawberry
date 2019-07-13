local skyent = require 'skynet'
local service = require 'service'
local util = require 'db.util'
local lfs = require 'lfs'
local log = require "chestnut.skynet.log"
local table_dump = require 'luaTableDump'

local function init()
    local db = util.connect_mysql()
    -- local fd = io.open('./config/mysql/update_db.sql')
    -- local sql = fd:read('a')
    -- log.info(sql)
    -- local res = db:query(sql)
    -- if res.errno then
    --     log.error('%s', util.dump(res))
    -- end
    local res = db:query('SELECT * FROM tb_database_version;')
    if res.errno then
        log.error('%s', util.dump(res))
    end
    log.info('%s', table_dump(res))
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
