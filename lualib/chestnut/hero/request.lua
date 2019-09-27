local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.hero.context"
local servicecode = require "enum.servicecode"
local client = require "client"
local pcall = pcall
local assert = assert
local REQUEST = client.request()
local traceback = debug.traceback

function REQUEST.fetch_heros(fd, args)
    return context.fetch_heros(fd, args)
end

function REQUEST.fetch_hero(fd, args)
    return context.fetch_hero(fd, args)
end

return REQUEST
