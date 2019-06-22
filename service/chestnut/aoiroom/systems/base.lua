local tiny = require "tiny"
local entity = require "room.components"

local system = tiny.processingSystem()

system.filter = tiny.requireAll("base")

function system:process(e, dt, ... )
	-- body
end

function system:match(world, conf,  ... )
	-- body

	local i   = entity()
	i.base.uid     = assert(conf.uid)
	i.base.session = assert(conf.session)
	i.base.udphost = assert(conf.udphost)
	i.base.udpport = assert(conf.udphost)
	i.base.udpgate = assert(conf.udpgate)

	world:addEntity(i)
end


return system