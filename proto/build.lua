local basefd = io.open('base.sproto', 'r')
local basec2sfd = io.open('base.c2s.sproto', 'r')
local bases2cfd = io.open('base.s2c.sproto', 'r')
local pokerfd = io.open('poker.sproto', 'r')
local pokerc2sfd = io.open('poker.c2s.sproto', 'r')
local pokers2cfd = io.open('poker.s2c.sproto', 'r')
local mahjongfd = io.open('mahjong.sproto', 'r')
local mahjongc2sfd = io.open('mahjong.c2s.sproto', 'r')
local mahjongs2cfd = io.open('mahjong.s2c.sproto', 'r')
local ballfd = io.open('ball.sproto', 'r')
local ballc2sfd = io.open('ball.c2s.sproto', 'r')
local balls2cfd = io.open('ball.s2c.sproto', 'r')


local base = basefd:read('a')
local basec2s = basec2sfd:read('a')
local bases2c = bases2cfd:read('a')

local poker = pokerfd:read('a')
local pokerc2s = pokerc2sfd:read('a')
local pokers2c = pokers2cfd:read('a')

local mahjong = mahjongfd:read('a')
local mahjongc2s = mahjongc2sfd:read('a')
local mahjongs2c = mahjongs2cfd:read('a')

local ball = ballfd:read('a')
local ballc2s = ballc2sfd:read('a')
local balls2c = balls2cfd:read('a')

basefd:close()
basec2sfd:close()
bases2cfd:close()

pokerfd:close()
pokerc2sfd:close()
pokers2cfd:close()

mahjongfd:close()
mahjongc2sfd:close()
mahjongs2cfd:close()

ballfd:close()
ballc2sfd:close()
balls2cfd:close()

local c2s = base .. ball .. basec2s .. ballc2s
local s2c = base .. ball .. bases2c .. balls2c

local c2sfd = io.open('c2s.sproto', 'w+')
local s2cfd = io.open('s2c.sproto', 'w+')

c2sfd:write(c2s)
s2cfd:write(s2c)

c2sfd:close()
s2cfd:close()
