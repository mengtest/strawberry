local AhievementSystem = require "chestnut.systems.AhievementSystem"
local FuncOpenSystem = require "chestnut.systems.FuncOpenSystem"
local LevelSystem = require "chestnut.systems.LevelSystem"
local PackageSystem = require "chestnut.systems.PackageSystem"
local RoomSystem = require "chestnut.systems.RoomSystem"
local UserSystem = require "chestnut.systems.UserSystem"
local log = require "chestnut.skynet.log"

local traceback = debug.traceback
local table_insert = table.insert

local Processors = {}

function Processors:on_data_init(dbData)
    AhievementSystem.on_data_init(self, dbData)
    FuncOpenSystem.on_data_init(self, dbData)
    PackageSystem.on_data_init(self, dbData)
    RoomSystem.on_data_init(self, dbData)
    UserSystem.on_data_init(self, dbData) 
end

function Processors:on_data_save(dbData)
    -- body
    AhievementSystem.on_data_save(self, dbData)
    FuncOpenSystem.on_data_save(self, dbData)
    PackageSystem.on_data_save(self, dbData)
    RoomSystem.on_data_save(self, dbData)
    UserSystem.on_data_save(self, dbData) 
end

function Processors:on_enter()
    RoomSystem.on_enter(self)
end

function Processors:on_exit()
    
end

function Processors:on_new_day()
end

return Processors