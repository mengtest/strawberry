local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local mime = require "gm.web.mime"
local urls = require "gm.web.urls"
local static_cache = {}
local cache = true
local root = skynet.getenv "http_root"

local _M = {}

local function unpack_seg(text, s)
	assert(text and s)
	local from = text:find(s, 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	else
		return text
	end
end

local function unpack_line(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local function split_file_name(path, ... )
	-- body
	assert(type(path) == "string")
	return ""
end

local function split_file_suffix(path, ... )
	-- body
	return ""
end

local function parse( ... )
	-- body
	local str = tostring( ... )
	if str and #str > 0 then
		local r = {}	
		local function split( str )
			-- body
			local p = string.find(str, "=")
			local key = string.sub(str, 1, p - 1)
			local value = string.sub(str, p + 1)
			r[key] = value
	 	end
		local s = 1
		repeat
			local p = string.find(str, "&", s)
			if p ~= nil then 
				local frg =	string.sub(str, s, p - 1)
				s = p + 1
				split(frg)
			else
				local frg =	string.sub(str, s)
				split(frg)
				break
			end
		until false
		return r
	else
		return str
	end
end

local function parse_file( header, boundary, body )
	-- body
	local line = ""
	local file = ""
	local last = body
	local mark = string.gsub(boundary, "^-*(%d+)-*", "%1")
	line, last = unpack_line(last)
	assert(string.match(line, string.format("^-*(%s)-*", mark)))
	line, last = unpack_line(last)
	line, last = unpack_line(last)
	line, last = unpack_line(last)
	line, last = unpack_line(last)
	while line do
		if string.match(line, string.format("^-*(%s)-*", mark)) then
			break
		else
			file = file .. line .. "\n" 
			line, last = unpack_line(last)
		end
	end
	header["content-type"] = nil
	return file, header
end

local function parse_content_type(content_type, ... )
	-- body
	assert(content_type)
	local res = {}
	local t, param = unpack_seg(content_type, ";")
	if t then
		res.type = t
		if t == "multipart/form-data" then
			local idx = string.find(c, "=")
			local boundary = string.sub(c, idx+1)
			res.boundary = boundary
			return res
		else
			local parameter = {}
			while param do
				local p, e = unpack_seg(param, ";")
				if p then
					local k, v = unpack_seg(p, "=")
					k = tostring(k)
					parameter[k] = v
					param = e
				else
				end
			end
			res.parameter = parameter
			return res
		end
	else
		assert(t)
	end
end

local function post_handler(path, method, query, ... )
	-- body
	for k,v in pairs(urls) do
		if string.match(path, k) then
			local args = {}
			args.method = "post"
			args.query = query
			local ok, err = pcall(v, args)
			if ok then
				return true, code, {}, err
			else
				local bodyfunc = "internal error."
				return true, 500, {}, bodyfunc
			end
		end
	end
	return false
end

function _M.handle_file(code, path, header, body,  ... )
	-- body
	local mime_version = header["mime-version"]
	local content_type = header["content-type"]
	local content_transfer_encoding = header["content-transfer-encoding"]
	local content_disposition = header["content-disposition"]
	local content_length = header["content-length"]
	local res = parse_content_type(content_type)
	local t = res.type
	if t == "application/x-www-form-urlencoded" then
		return false
	elseif t == "application/json" then
		return false
	elseif t == "multipart/form-data" then
		local boundary = res.boundary
		local res = parse_file(header, boundary, body)
		return post_handler(path, "file", res)
	else
		return false
	end
end

function _M.handle_post(path, header, body, post_handler, ... )
	-- body
	return post_handler(path, "post", body)
end

local function fetch_static(path, ... )
	-- body
	if cache then
		if static_cache[path] then
			return true, static_cache[path]
		else
			local fpath = root .. path
			local fd = io.open(fpath, "r")
			if fd == nil then
				log.error(string.format("fpath is wrong, %s", fpath))
				return false
			else
				local r = fd:read("a")
				fd:close()
				static_cache[path] = r
				return true, r
			end	
		end
	else
		local fpath = root .. path
		local fd = io.open(fpath, "r")
		if fd == nil then
			log.error(string.format("fpath is wrong, %s", fpath))
			return false
		else
			local r = fd:read("a")
			fd:close()
			static_cache[path] = r
			return true, r
		end	
	end
end

function _M.handle_static(code, path, header, body, handle_static, ... )
	-- body
	if string.match(path, "^/[%w%./-]+%.%w+") then
		local ok, res = fetch_static(path)
		return ok, code, {}, res
	else
		local mime_version = header["mime-version"]
		local content_type = header["content-type"]
		local content_transfer_encoding = header["content-transfer-encoding"]
		local content_disposition = header["content-disposition"]
		local content_length = header["content-length"]
		local name = split_file_name(path)
		for _,v in pairs(mime) do
			local fpath = path .. "." .. v[1]
			local ok, res = fetch_static(fpath)
			if ok then
				return ok, code, {}, res
			end
		end

		return false
	end
end

function _M.handle_get(code, path, query, header, body, ... )
	-- body
	return post_handler(path, "get", query)
end

return _M