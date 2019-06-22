local skynet = require "skynet"
local vector = require "chestnut.vector"
local sortedvector = require "chestnut.sortedvector"

skynet.start(function ()
	-- body
	local ok, err = pcall(function ( ... )
		-- body
		local a = vector(6)
		print("len of a:", #a)
		for i=1,10 do
			local rand = math.random(1, 1000);
			a:push_back(rand)
		end
		print("len of a:", #a)
		for k,v in ipairs(a) do
			print(k,v)
		end
		a:sort(function (l, r, ... )
			-- body
			return (l - r)
		end)
		print("after sort:")
		for i,v in pairs(a) do
			print(i,v)
		end

		print('sortedvector ---------------begin')
		local b = sortedvector(function (l, r, ... )
			-- body
			return l - r;
		end)()
		for i=1,10 do
			local rand = math.random(1, 1000);
			print("push", rand)
			b:push(rand)
		end
		print('sortedvector ---------------pairs')
		for i,v in pairs(b) do
			print(i,v)
		end

		b:erase(148)
		print('sortedvector ---------------ipairs')
		for i,v in ipairs(b) do
			print(i,v)
		end
		b:eraseat(3)
		print('sortedvector ---------------ipairs')
		for i,v in ipairs(b) do
			print(i,v)
		end
		print('indexof')
		print('index of 175', b:indexof(175))

		print('sortedvector ---------------end')
	end)
	if not ok then
		print(err)
	end
	skynet.exit()
end)