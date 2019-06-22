local skynet = require "skynet"
local zset = require 'zset'

skynet.start(function ( ... )
    -- body
    local zs = zset.new()
    for i=1,1000000 do
        local score = math.random(1, 10000000)
        zs:add(score, tostring(i))
    end
end)