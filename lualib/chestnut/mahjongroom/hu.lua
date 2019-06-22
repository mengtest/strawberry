-- local log = require "log"
local hutype = require "chestnut.mahjongroom.hutype"

local function check_qidui(cards, ... )
	-- body
	assert(cards and #cards > 0)
	local qing   = true
	local jiang  = 0
	local gang   = 0
	local single = 0

	local len = #cards
	local idx = 1

	local a = cards[idx]
	idx = idx + 1
	while idx <= len do
		if idx > len then
			single = single + 1
			break
		end
		local b = cards[idx]
		idx = idx + 1
		if b:eq(a) then
			if idx <= len then
				local c = cards[idx]
				idx = idx + 1
				if a:eq(c) then
					if idx <= len then
						local d = cards[idx]
						idx = idx + 1
						if d:eq(c) then
							jiang = jiang + 2
							gang = gang + 1
							if idx <= len then
								local e = cards[idx]
								idx = idx + 1
								if e:tof() ~= a:tof() then
									qing = false
								end
								a = e
							else
								break
							end
						else
							jiang = jiang + 1
							single = single + 1
							if d:tof() ~= c:tof() then
								qing = false
							end
							a = d
						end
					else
						break
					end
				else
					if a:tof() ~= c:tof() then
						qing = false
					end
					jiang = jiang + 1
					a = c
				end
			else
				jiang = jiang + 1
				break
			end	
		else
			single = single + 1
			if b:tof() ~= a:tof() then
				qing = false
			end
			a = b
		end
	end

	local res = {}
	res.qing = qing
	res.jiang = jiang
	res.gang = gang
	res.single = single
	return res
end

local function check_qidui_hu(cards, ... )
	-- body
	assert(cards and #cards > 0)
	local args = check_qidui(cards)
	local qing   = args.qing
	local jiang  = args.jiang
	local gang   = args.gang
	local single = args.single

	local res = {}
	res.gang = gang
	if jiang == 7 and qing and gang >= 1 then
		res.code = hutype.QINGLONGQIDUI
	elseif jiang == 7 and qing then
		res.code = hutype.QINGQIDUI
	elseif jiang == 7 and gang >= 1 then
		res.code = hutype.LONGQIDUI
	elseif jiang == 7 then
		res.code = hutype.QIDUI
	else
		res.code = hutype.NONE
	end
	return res
end

local function check_qidui_jiao(cards, ... )
	-- body
	assert(cards and #cards > 0)
	local args = check_qidui(cards)
	local qing   = args.qing
	local jiang  = args.jiang
	local gang   = args.gang
	local single = args.single

	local res = {}
	res.gang = gang
	if qing and jiang == 6 and single == 1 and gang >= 1 then
		res.code = hutype.QINGLONGQIDUI
	elseif qing and jiang == 6 and single == 1 then
		res.code = hutype.QINGQIDUI
	elseif jiang == 6 and single == 1 and gang >= 1 then
		res.code = hutype.LONGQIDUI
	elseif jiang == 6 and single == 1 then
		res.code = hutype.QIDUI
	else
		res.code = hutype.NONE
	end
	return res
end

local function check_put(putcards, ... )
	-- body
	assert(putcards and #putcards > 0)
	local qing = true
	local gang = 0
	local ctype = putcards[1].cards[1]:tof()
	
	for k,v in pairs(putcards) do
		if v.cards[1]:tof() ~= ctype then
			qing = false
		end
		if #v.cards == 4 then
			gang = gang + 1
		end
	end
	local res = {}
	res.qing = qing
	res.gang = gang
	res.ctype = ctype
	return res
end

local function check_sichuan(cards, putcards, ... )
	-- body
	local qing   = true
	local jiang  = 0
	local tong3  = 0
	local lian3  = 0
	local single = 0
	local lian2  = 0
	local ge2 = 0
	local gang   = 0

	local len = #cards
	local idx = 1
	local a = cards[idx]
	idx = idx + 1
	while idx <= len do
		if idx > len then
			single = single + 1
			break
		end
		local b = cards[idx]
		idx = idx + 1
		if b:eq(a) then
			if idx > len then
				jiang = jiang + 1
				break
			end
			local c = cards[idx]
			idx = idx + 1
			if c:eq(a) then
				if idx > len then
					tong3 = tong3 + 1
					break
				end
				local d = cards[idx]
				idx = idx + 1
				if d:eq(a) then
					if idx > len then
						jiang = jiang + 1
						gang = gang + 1
						break
					end
					local e = cards[idx]
					idx = idx + 1
					if e:tof() == a:tof() then
						if e:nof() == a:nof() + 1 then
							if idx > len then
								tong3 = tong3 + 1
								lian2 = lian2 + 1
								gang = gang + 1
								break
							end
							local f = cards[idx]
							idx = idx + 1
							if f:eq(e) then
								if idx > len then
									jiang = jiang + 3
									gang = gang + 1
									break
								end
								local g = cards[idx]
								idx = idx + 1
								if g:tof() == f:tof() then
									if g:nof() == f:nof() + 1 then
										if idx > len  then
											jiang = jiang + 3
											single = single + 1
											gang = gang + 1
											break
										end
										local h = cards[idx]
										idx = idx + 1
										if h:eq(g) then
											lian3 = lian3 + 2
											jiang = jiang + 1
											if idx <= len then
												local i = cards[idx]
												idx = idx + 1
												if i:tof() ~= a:tof() then
													qing = false
												end
												a = i
											else
												break
											end
										else
											jiang = jiang + 3
											single = single + 1
											gang = gang + 1
											if h:tof() ~= g:tof() then
												qing = false
											end
											a = h
										end
									else
										break
									end
								else
									qing = false
									jiang = jiang + 3
									gang = gang + 1
									a = g
								end
							elseif f:tof() == e:tof() then
								if f:nof() == e:nof() + 1 then
									tong3 = tong3 + 1
									lian3 = lian3 + 1
									gang = gang + 1
									if idx <= len then
										local g = cards[idx]
										idx = idx + 1
										if g:tof() ~= a:tof() then
											qing = false
										end
										a = g
									else
										break
									end
								else
									tong3 = tong3 + 1
									lian2 = lian2 + 1
									gang = gang + 1
									a = f
								end
							else
								qing = false
								tong3 = tong3 + 1
								lian2 = lian2 + 1
								gang = gang + 1
								a = f
							end
						else
							jiang = jiang + 2
							gang = gang + 1
							a = e
						end
					else
						qing = false
						jiang = jiang + 2
						gang = gang + 1
						a = e
					end
				elseif d:tof() == a:tof() then
					if d:nof() == a:nof() + 1 then
						if idx > len then
							jiang = jiang + 1
							lian2 = lian2 + 1
							break
						end
						local e = cards[idx]
						idx = idx + 1
						if e:eq(d) then
							tong3 = tong3 + 1
							a = d
							idx = idx - 1
						elseif e:tof() == d:tof() then
							if e:nof() == d:nof() + 1 then
								if idx <= len then
									local f = cards[idx]
									idx = idx + 1
									if f:tof() == e:tof() then
										if f:nof() == e:nof() + 1 then
											tong3 = tong3 + 1
											lian3 = lian3 + 1
											if idx <= len then
												local g = cards[idx]
												idx = idx + 1
												if g:tof() ~= f:tof() then
													qing = false
												end
												a = g
											else
												break
											end
										else
											jiang = jiang + 1
											lian3 = lian3 + 1
											a = f
										end
									else
										qing = false
										jiang = jiang + 1
										lian3 = lian3 + 1
										a = f
									end
								else
									lian3 = lian3 + 1
									jiang = jiang + 1
									break
								end
							else
								jiang = jiang + 2
								gang = gang + 1
								a = e
							end
						else
							qing = false
							jiang = jiang + 2
							gang = gang + 1
							a = e
						end
					else
						tong3 = tong3 + 1
						a = d
					end
				else
					qing = false
					tong3 = tong3 + 1
					a = d
				end
			elseif c:tof() == b:tof() then
				if c:nof() == b:nof() + 1 then
					if idx > len then
						jiang = jiang + 1
						single = single + 1
						break
					end
					local d = cards[idx]
					idx = idx + 1
					if d:eq(c) then
						if idx > len then
							jiang = jiang + 2
							break
						end
						local e = cards[idx]
						idx = idx + 1
						if e:eq(d) then
							if idx > len then
								jiang = jiang + 1
								tong3 = tong3 + 1
								break
							end
							local f = cards[idx]
							idx = idx + 1
							if f:eq(e) then
								if idx > len then
									jiang = jiang + 3
									break
								end
								local g = cards[idx]
								idx = idx + 1
								if g:tof() == e:tof() then
									if g:nof() == e:nof() + 1 then
										if idx < len then
											jiang = jiang + 3
											single = single + 1
											break
										end
										local h = cards[idx]
										idx = idx + 1
										if h:eq(g) then
											jiang = jiang + 1
											lian3 = lian3 + 2
											if idx <= len then
												local i = cards[idx]
												if i:tof() ~= a:tof() then
													qing = false
												end
											else
												break
											end
										else
											jiang = jiang + 3
											single = single + 1
											a = h
										end
									else
										jiang = jiang + 3
										a = g
									end
								else
									qing = false
									jiang = jiang + 3
									a = g
								end
							else
								jiang = jiang + 1
								tong3 = tong3 + 1
								a = f
							end
						elseif e:tof() == d:tof() then
							if e:nof() == d:nof() + 1 then
								if idx > len then
									lian3 = lian3 + 1
									lian2 = lian2 + 1
									break
								end
								local f = cards[idx]
								idx = idx + 1
								if f:eq(e) then
									lian3 = lian3 + 2
									if idx > len then
										break
									else
										local g = cards[idx]
										idx = idx + 1
										if g:tof() ~= f:tof() then
											qing = false
										end
										a = g
									end
								else
									lian3 = lian3 + 1
									lian2 = lian2 + 1
									if f:tof() ~= e:tof() then
										qing = false
									end
									a = f
								end
							else
								jiang = jiang + 2
								a = e
							end
						else
							qing = false
							jiang = jiang + 2
							a = e
						end
					elseif d:tof() == c:tof() then
						if d:nof() == c:nof() + 1 then
							if idx > len then
								jiang = jiang + 1
								lian2 = lian2 + 1
								break
							end
							local e = cards[idx]
							idx = idx + 1
							if e:tof() == d:tof() then
								if e:nof() == d:nof() + 1 then
									jiang = jiang + 1
									lian3 = lian3 + 1
									if idx <= len then
										local f = cards[idx]
										idx = idx + 1
										if f:tof() ~= e:tof() then
											qing = false
										end
										a = f
									else
										
										break
									end
								else
									break
								end
							else
								break
							end
						else
							jiang = jiang + 1
							a = c
							idx = idx - 1
						end
					else
						qing = false
						jiang = jiang + 1
						a = c
						idx = idx - 1
					end
				else
					jiang = jiang + 1
					a = c
				end
			else
				qing = false
				jiang = jiang + 1
				a = c
			end
		elseif b:tof() == a:tof() then
			if b:nof() == a:nof() + 1 then
				if idx > len then
					lian2 = lian2 + 1
					break
				end
				local c = cards[idx]
				idx = idx + 1
				if c:eq(b) then
					if idx <= len then
						local d = cards[idx]
						idx = idx + 1
						if d:eq(c) then
							if idx <= len then
								local e = cards[idx]
								idx = idx + 1
								if e:eq(d) then
									if idx <= len then
										local f = cards[idx]
										idx = idx + 1
										if f:tof() == e:tof() then
											if f:nof() == e:nof() + 1 then
												tong3 = tong3 + 1
												lian3 = lian3 + 1
												if idx <= len then
													local g = cards[idx]
													idx = idx + 1
													if g:tof() ~= a:tof() then
														qing = false
													end
													a = g
												else
													break
												end
											else
												break
											end
										else
											break
										end
									else
										break
									end
								elseif e:tof() == d:tof() then
									if e:nof() == d:nof() + 1 then
										lian3 = lian3 + 1
										jiang = jiang + 1
										if idx <= len then
											local f = cards[idx]
											idx = idx + 1
											if f:tof() ~= e:tof() then
												qing = false
											end
											a = f
										else
											break
										end
									else
										break
									end
								else
									break
								end
							else
								break
							end
						elseif d:tof() == c:tof() then
							if d:nof() == c:nof() + 1 then
								if idx <= len then
									local e = cards[idx]
									idx = idx + 1
									if e:eq(d) then
										if idx <= len then
											local f = cards[idx]
											idx = idx + 1
											if f:tof() == e:tof() then
												if f:nof() == e:nof() + 1 then
													print("step 1")
													lian3 = lian3 + 2
													if idx <= len then
														local g = cards[idx]
														idx = idx + 1
														if g:tof() ~= f:tof() then
															qing = false
														end
														a = g
													else
														break
													end
												else
													break
												end
											else
												break
											end
										else
											break
										end
									else
										break
									end
								else
									break
								end
							else
								break
							end
						end
					else
						break
					end
				elseif c:tof() == b:tof() then
					if c:nof() == b:nof() + 1 then
						if idx <= len then
							local d = cards[idx]
							idx = idx + 1
							if d:eq(c) then
								if idx <= len then
									local e = cards[idx]
									idx = idx + 1
									if e:eq(d) then
										if idx <= len then
											local f = cards[idx]
											idx = idx + 1
											if f:eq(e) then
												lian3 = lian3 + 1
												tong3 = tong3 + 1
												gang = gang + 1
												if idx <= len then
													local g = cards[idx]
													idx = idx + 1
													if g:tof() ~= a:tof() then
														qing = false
													end
													a = g
												else
													break
												end
											else
												lian3 = lian3 + 1
												jiang = jiang + 1
												if f:tof() ~= a:tof() then
													qing = false
												end
												a = f
											end
										else
											lian3 = lian3 + 1
											jiang = jiang + 1
											break
										end
									else
										lian3 = lian3 + 1
										a = d
										idx = idx - 1
									end
								else
									lian2 = lian2 + 1
									jiang = jiang + 1
									break
								end
							else
								lian3 = lian3 + 1
								if d:tof() ~= c:tof() then
									qing = false
								end
								a = d
							end
						else
							lian3 = lian3 + 1
							break
						end
					else
						lian2 = lian2 + 1
						a = c
					end
				else
					qing = false
					lian2 = lian2 + 1
					a = c
				end
			elseif b:nof() == a:nof() + 2 then
				if idx > len then
					ge2 = ge2 + 1
					break
				end
				local c = cards[idx]
				idx = idx + 1
				if c:eq(b) then
				elseif c:tof() == b:tof() then
					if c:nof() == b:nof() + 1 then

					else
						ge2 = ge2 + 1
						a = c
					end
				else
					qing = false
					ge2 = ge2 + 1
					a = c
				end
			else
				single = single + 1
				a = b
			end
		else
			qing = false
			single = single + 1
			a = b
		end
	end

	local res = {}
	res.qing = qing
	res.jiang = jiang
	res.tong3 = tong3
	res.lian3 = lian3
	res.single = single
	res.lian2 = lian2
	res.ge2 = ge2
	res.gang = gang
	res.ctype = a:tof()
	return res
end

local _M = {}

function _M.check_sichuan_hu(cards, putcards, ... )
	-- body
	assert(cards and putcards)
	local res = check_qidui_hu(cards)
	if res.code ~= hutype.NONE then
		return res
	end

	local len = #cards
	local args = check_sichuan(cards, putcards)
	local qing   = args.qing
	local jiang  = args.jiang
	local tong3  = args.tong3
	local lian3  = args.lian3
	local single = args.single
	local lian2  = args.lian2
	local gang   = args.gang
	local ctype  = args.ctype

	if #putcards > 0 then
		local putargs = check_put(putcards)
		if putargs.qing and qing then
			if putargs.ctype ~= ctype then
				qing = false
			end
		else
			qing = false
		end
		gang = gang + putargs.gang
	end

	local res = {}
	res.code = hutype.NONE
	res.gang = gang
	if jiang * 2 + tong3 * 3 + lian3 * 3 == len then
		if len == 2 and jiang == 1 then
			if qing and gang == 4 then
				res.code = hutype.QINGSHIBALUOHAN
			elseif gang == 4 then
				res.code = hutype.SHIBALUOHAN
			elseif qing then
				res.code = hutype.QINGJINGOUDIAO
			else
				res.code = hutype.JINGOUDIAO
			end
		elseif len == 5 then
			if jiang == 1 and tong3 == 1 and qing then
				res.code = hutype.QINGDUIDUI
			elseif jiang == 1 and tong3 == 1 then
				res.code = hutype.DUIDUIHU
			elseif jiang == 1 and qing then
				res.code = hutype.QINGYISE
			elseif jiang == 1 then
				res.code = hutype.PINGHU
			end
		elseif len == 8 then
			if jiang == 1 and tong3 == 2 and qing then
				res.code = hutype.QINGDUIDUI
			elseif jiang == 1 and tong3 == 2 then
				res.code = hutype.DUIDUIHU
			elseif jiang == 1 and qing then
				res.code = hutype.QINGYISE
			elseif jiang == 1 then
				res.code = hutype.PINGHU 
			end
		elseif len == 11 then
			if jiang == 1 and tong3 == 3 and qing then
				res.code = hutype.QINGDUIDUI
			elseif jiang == 1 and tong3 == 3 then
				res.code = hutype.DUIDUIHU
			elseif jiang == 1 and qing then
				res.code = hutype.QINGYISE
			elseif jiang == 1 then
				res.code = hutype.PINGHU
			end
		elseif len == 14 then
			if jiang == 1 and tong3 == 4 and qing then
				res.code = hutype.QINGDUIDUI
			elseif jiang == 1 and tong3 == 4 then
				res.code = hutype.DUIDUIHU
			elseif jiang == 1 and qing then
				res.code = hutype.QINGYISE
			elseif jiang == 1 then
				res.code = hutype.PINGHU
			end
		end
	end
	return res
end

function _M.check_sichuan_jiao(cards, putcards, ... )
	-- body
	assert(cards and putcards)
	local res = check_qidui_hu(cards)
	if res.code ~= hutype.NONE then
		return res
	end

	local len = #cards
	local args = check_sichuan(cards, putcards)
	local qing   = args.qing
	local jiang  = args.jiang
	local tong3  = args.tong3
	local lian3  = args.lian3
	local single = args.single
	local lian2  = args.lian2
	local ge2    = args.ge2
	local gang   = args.gang
	local ctype  = args.ctype

	print("len", len)
	print("qing:", qing)
	print("jiang", jiang)
	print("tong3", tong3)
	print("lian3", lian3)
	print("single", single)
	print("lian2", lian2)
	print("gang", gang)
	print("ge2", ge2)

	if #putcards > 0 then
		local putargs = check_put(putcards)
		if putargs.qing and qing then
			if putargs.ctype ~= ctype then
				qing = false
			end
		else
			qing = false
		end
		gang = gang + putargs.gang
	end

	local res = {}
	res.code = hutype.NONE
	res.gang = gang
	assert(jiang * 2 + tong3 * 3 + lian3 * 3 + single * 1 + lian2 * 2 + ge2 * 2 == len)
	if len == 1 and single == 1 then
		if qing and gang == 4 then
			res.code = hutype.QINGSHIBALUOHAN
		elseif gang == 4 then
			res.code = hutype.SHIBALUOHAN
		elseif qing then
			res.code = hutype.QINGJINGOUDIAO
		else
			res.code = hutype.JINGOUDIAO
		end
	elseif len == 4 then
		if qing and jiang == 2 then
			res.code = hutype.QINGDUIDUI
		elseif jiang == 2 then
			res.code = hutype.DUIDUIHU
		elseif qing and jiang == 1 and lian2 == 1 then
			res.code = hutype.QINGYISE
		elseif qing and single == 1 and lian3 == 1 then
			res.code = hutype.QINGYISE
		elseif qing and single == 1 and ge2 == 1 then
			res.code = hutype.QINGYISE
		elseif jiang == 1 and lian2 == 1 then
			res.code = hutype.PINGHU
		elseif single == 1 and lian3 == 1 then
			res.code = hutype.PINGHU
		elseif single == 1 and ge2 == 1 then
			res.code = hutype.PINGHU
		else
			res.code = hutype.NONE
		end
	elseif len == 7 then
		if qing and jiang == 2 and tong3 == 1 then
			res.code = hutype.QINGDUIDUI
		elseif jiang == 2 and tong3 == 1 then
			res.code = hutype.DUIDUIHU
		elseif qing and single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.QINGYISE
		elseif qing and single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.QINGYISE
		elseif qing and single == 0 and jiang == 1 and ge2 == 1 then
			res.code = hutype.QINGYISE
		elseif single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and ge2 == 1 then
			res.code = hutype.PINGHU
		else
			res.code = hutype.NONE
		end
	elseif len == 10 then
		if qing and jiang == 2 and tong3 == 2 then
			res.code = hutype.QINGDUIDUI
		elseif jiang == 2 and tong3 == 2 then
			res.code = hutype.DUIDUIHU
		elseif qing and single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.QINGYISE
		elseif qing and single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.QINGYISE
		elseif qing and single == 0 and jiang == 1 and ge2 == 1 then
			res.code = hutype.QINGYISE
		elseif single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and ge2 == 1 then
			res.code = hutype.PINGHU
		else
			res.code = hutype.NONE
		end
	elseif len == 13 then
		if qing and jiang == 2 and tong3 == 3 then
			res.code = hutype.QINGDUIDUI
		elseif jiang == 2 and tong3 == 3 then
			res.code = hutype.DUIDUIHU
		elseif qing and single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.QINGYISE
		elseif qing and single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.QINGYISE
		elseif single == 1 and jiang == 0 and lian2 == 0 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and lian2 == 1 then
			res.code = hutype.PINGHU
		elseif single == 0 and jiang == 1 and ge2 == 1 then
			res.code = hutype.PINGHU			
		else
			res.code = hutype.NONE
		end
	end
	return res
end

return _M