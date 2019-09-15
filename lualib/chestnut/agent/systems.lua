local log = require "chestnut.skynet.log"
local ahievement = require "chestnut.achievement.context"
local PackageSystem = require "chestnut.bag.context"
local RoomSystem = require "chestnut.room.context"
local hero = require "chestnut.hero.context"
local FuncOpenSystem = require "chestnut.systems.funcopen"
local user = require "chestnut.systems.user"

local traceback = debug.traceback
local table_insert = table.insert

local Processors = {}

function Processors:on_data_init(dbData)
    log.info("on data init")
    user.on_data_init(self, dbData)
    ahievement.on_data_init(self, dbData)
    FuncOpenSystem.on_data_init(self, dbData)
    PackageSystem.on_data_init(self, dbData)
    RoomSystem.on_data_init(self, dbData)
    hero.on_data_init(self, dbData)
end

function Processors:on_data_save(dbData)
    -- body
    ahievement.on_data_save(self, dbData)
    FuncOpenSystem.on_data_save(self, dbData)
    PackageSystem.on_data_save(self, dbData)
    RoomSystem.on_data_save(self, dbData)
    user.on_data_save(self, dbData)
    hero.on_data_save(self, dbData)
end

function Processors:on_enter()
    user.on_enter(self)
    FuncOpenSystem.on_enter(self)
    RoomSystem.on_enter(self)
    hero.on_enter(self)
end

function Processors:on_exit()
    RoomSystem.on_exit(self)
    FuncOpenSystem.on_exit(self)
    user.on_exit(self)
end

function Processors:on_new_day()
end

return Processors
