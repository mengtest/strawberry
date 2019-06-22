local skynet = require "skynet"
local array = require "chestnut.array"

skynet.start(function ( ... )
	-- body
	local a = array(6)()
	a[1] = 'hell'
	a[2] = {}
	a[3] = 'hhhhhhhh'
	a[4] = 'syhlsh'
	for k,v in pairs(a) do
		print(k,v)
	end
	print('lenth of a:', #a)
	skynet.exit()
end)