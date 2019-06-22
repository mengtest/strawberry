------------------------------------------
-- 针对card数组转换成lead_type
------------------------------------------
local leadtype = require('lead_type')
local array = require('chestnut.array')
local _M = {}

-- 针对出的牌
function _M.parseLeadtype(arr)        -- [card]
	-- body
	if #arr <= 0 then
		return leadtype.NONE
	end
	local seqMap = array(13)()    -- 按照数字的排序  num ==> cnt
	local colMap = array(4)()     -- 按照类型的排序  type ==> cnt
	local numMap = {}             --                cnt  ==> num
	for _,v in ipairs(arr) do
		if seqMap[v.num] then
			seqMap[v.num] = seqMap[v.num] + 1
		else
			seqMap[v.num] = 1
		end
		if colMap[v.type] then
			colMap[v.type] = colMap[v.type] + 1
		else
			colMap[v.type] = 1
		end
	end
	if #arr == 1 then
		return leadtype.SINGLE
	elseif #arr == 2 then
		if seqMap[arr[1].num] == 2 then
			return leadtype.COUPLE
		end
	elseif #arr == 5 then
		local cnt = 0
		for k,v in pairs(seqMap) do
			if v >= 1 then
				cnt = cnt + 1
			end
			if v >= 2 then
				numMap[v] = k
			end
		end

		-- 判断葫芦与铁质
		if cnt == 2 then
			if numMap[3] and numMap[2] then
				return leadtype.HULU
			elseif numMap[4] then
				return leadtype.TIEZHI
			end
		end

		if cnt == 5 then
			-- 判断顺子与同花顺
			local scnt = 0
			local pre = 0
			for k,v in pairs(seqMap) do
				if v >= 1 then
					if pre == 0 then
						pre = v
						scnt = 1
					else
						if k ~= pre + 1 then
							break
						else
							scnt = scnt + 1
						end
					end
				else
					if pre ~= 0 then
						break
					end
				end
			end
			if scnt == cnt then
				if colMap[arr[1].type] == cnt then
					return leadtype.TONGHUASHUN
				else
					return leadtype.SHUNZI
				end
			else
				-- 判断同花
				if colMap[arr[1].type] == cnt then
					return leadtype.TONGHUA
				end
			end
		end
	end
	return leadtype.NONE
end

-- 针对所有牌
function _M.parseCards(arr)
	-- body
end

return _M