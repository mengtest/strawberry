local skynet = require "skynet"
local redis = require "redis"

skynet.start(function ( ... )
	-- body
	skynet.uniqueservice("redis")

	redis.set("hello", "world")
	print(redis.get("hello"))

end)