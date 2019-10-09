local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local context = require "chestnut.team.context"
local servicecode = require "enum.servicecode"
local REQUEST = require "request"
local pcall = pcall
local assert = assert
local traceback = debug.traceback

function REQUEST.fetch_teams(fd, args)
	return context.fetch_teams(fd, args)
end

function REQUEST.fetch_team(fd, args)
	return context.fetch_team(fd, args)
end

function REQUEST.create_team(fd, args)
	return context.create_team(fd, args)
end

function REQUEST.join_team(fd, args)
	return context.join_team(fd, args)
end

function REQUEST.fetch_myteams(fd, args)
	return context.fetch_myteams(fd, args)
end

function REQUEST.quit_team(fd, args)
	return context.quit_team(fd, args)
end

return REQUEST
