package.cpath = "../luaclib/?.so;" .. package.cpath
package.path = "../lualib/?.lua;" .. package.path

require "init"
class = cc.class

local leadboard = require "leadboard"

local function comp(_1, _2, ... )
	-- body
	if _1 > _2 then
		return 1
	elseif _1 == _2 then
		return 0
	else
		return -1
	end
end

local l = leadboard.new(100, comp)

for i=1,100 do
	print(l:push(i, comp))
end


-- local function f1(a, b, ... )
-- 	-- body
-- 	print(a, b)
-- 	local x = 1
-- 	while true do
-- 		x = x + 1
-- 		print(x)
-- 		if x % 10 == 0 then
-- 			local res = coroutine.yield(4)
-- 			print(res)
-- 		end
-- 	end
-- end

-- local function f2( ... )
-- 	-- body
-- 	while true do
-- 		print("test 2")
-- 		coroutine.yield()
-- 	end
-- end

-- local co1 = coroutine.create(f1)
-- local co2 = coroutine.create(f2)

-- print("begin")
-- local ok, res = coroutine.resume(co1, 1, 2)
-- print("res:", res)
-- coroutine.resume(co2)
-- coroutine.resume(co1, 3)
-- coroutine.resume(co2)



-- local leadboard = require "leadboard"
-- local l = leadboard.new(10)

-- local function comp(left, right, ... )
-- 	-- body
-- 	assert(type(left) == "number")
-- 	assert(type(right) == "number")
-- 	return left > right
-- end

-- l:push_back(12, comp)
-- l:push_back(122, comp)
-- l:push_back(132, comp)
-- l:push_back(7, comp)
-- l:push_back(643, comp)
-- l:push_back(98, comp)
-- l:push_back(111, comp)
-- l:push_back(32, comp)
-- l:push_back(25, comp)
-- l:push_back(94, comp)
-- l:push_back(65, comp)
-- l:push_back(198, comp)
-- l:push_back(322, comp)
-- l:push_back(56, comp)
-- l:push_back(111, comp)
-- l:push_back(142, comp)
-- l:push_back(56, comp)

-- local function printx(x, ... )
-- 	-- body
-- 	print(x)
-- end

-- l:foreach(printx)


-- local math3d = require "math3d"


-- local aabb1 = math3d.aabb(math3d.vector3(0, 0, 0), math3d.vector3(3, 3, 3))
-- local aabb2 = math3d.aabb(math3d.vector3(1, 1, 1), math3d.vector3(4, 4, 4))

-- local aabb1 = math3d.aabb(math3d.vector3(0, 0, 0), math3d.vector3(3, 3, 3))
-- -- local aabb2 = math3d.aabb(math3d.vector3(1, 1, 1), math3d.vector3(4, 4, 4))

-- local identity = math3d.matrix()
-- identity:trans(2, 2, 2)

-- identity:unpack()
-- local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = identity:unpack()
-- print(m13, m14, m15, m16)

-- aabb1:transform(identity)


-- local center = math3d.vector3(0, 0, 0)
-- aabb1:getCenter(center)
-- local x, y, z = center:unpack()
-- print(x, y, z)

-- local corners = {}
-- for i=1,8 do
-- 	table.insert(corners, math3d.vector3(0, 0, 0))
-- end
-- aabb1:getCorners(corners)

-- for i,v in ipairs(corners) do
-- 	local x, y, z = v:unpack()
-- 	print(x, y, z)
-- end

-- if aabb1:intersects(aabb2) then
-- 	print("ok")
-- else
-- 	print(false)
-- end


-- local queue = require "lqueue"

-- local q = queue.new(3)

-- for i=1,11 do
-- 	queue.enqueue(q, i)
-- end

-- -- print(queue.size(q))

-- for i=1,5 do
-- 	print(queue.dequeue(q))
-- end

-- for i=1,20 do
-- 	queue.enqueue(q, i * 10)
-- end

-- for i=1,8 do
-- 	print(queue.dequeue(q))
-- end

-- print(queue.size(q))
-- print(q.__cap)

-- local sz = queue.size(q)
-- for i=1,sz do
-- 	print(queue.dequeue(q))
-- end



-- local q = queue()

-- local r

-- local last = os.time()

-- for i=1,10 do
-- 	local item = {}
-- 	item.name = string.format("%d", i)
-- 	if i == 5 then
-- 		r = item
-- 	end
-- 	q:enqueue(item)
-- end

-- print(q:del(r))

-- print(q:size())

-- for i=1,10 do
-- 	local item = q:dequeue()
-- 	if item then
-- 		print(item.name)
-- 	end
-- end

-- print(q:size())

-- for i=1,6 do
-- 	local item = {}
-- 	item.name = string.format("%d", i * 10)
-- 	if i == 5 then
-- 		r = item
-- 	end
-- 	q:enqueue(item)
-- end

-- for i=1,11 do
-- 	local item = q:dequeue()
-- 	if item then
-- 		print(item.name)
-- 	end
-- end

-- print(os.time() - last)



-- print(q:del(r))

-- for i=1,8 do
-- 	local item = q:dequeue()
-- 	if item then
-- 		print(item.name)
-- 	end
-- end

-- print(q:size())

-- q:test()
