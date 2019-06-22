local socket = require "skynet.socket"
local skynet = require "skynet"
local ss = require "https.sssl"

local readbytes = socket.read
local writebytes = socket.write

local sockethelper = {}
local socket_error = setmetatable({} , { __tostring = function() return "[Socket Error]" end })

sockethelper.socket_error = socket_error

sockethelper.fds  = {}
sockethelper.ssls = {}

local fds  = sockethelper.fds
local ssls = sockethelper.ssls

local function preread(fd, str)
	return function (sz)
		if str then
			if sz == #str or sz == nil then
				local ret = str
				str = nil
				return ret
			else
				if sz < #str then
					local ret = str:sub(1,sz)
					str = str:sub(sz + 1)
					return ret
				else
					sz = sz - #str
					local ret = readbytes(fd, sz)
					if ret then
						return str .. ret
					else
						error(socket_error)
					end
				end
			end
		else
			local ret = readbytes(fd, sz)
			if ret then
				return ret
			else
				error(socket_error)
			end
		end
	end
end

function sockethelper.readfunc(fd, pre)
	if pre then
		assert(false)
		return preread(fd, pre)
	end
	return function (sz)
		local fds = assert(sockethelper.fds)
		local s = assert(fds[fd])
		if type(sz) == "number" then			
			if sz and  sz <= 0 then
				local res = s.res
				s.res = ""
				return res
			end
			local res = assert(s.res)
			while #res < sz do
				socket.block(fd)
				local buf = readbytes(fd)
				if buf then
					assert(ssl:ss() == ss.ss_connected)
					ssl:poll(buf)
				else
					error(socket_error)	
				end
				res = assert(s.res)
			end
			local p = res:sub(1, 1 + sz)
			s.res = res:sub(1 + sz)
			return p
		else
			local ssl = assert(s.ssl)
			local res = s.res
			while #res <= 0 do
				socket.block(fd)
				local buf = readbytes(fd)
				if buf then
					assert(ssl:ss() == ss.ss_connected)
					ssl:poll(buf)
					res = s.res
				else
					error("readfunc:", socket_error)	
				end
			end
			local res = s.res
			s.res = ""
			return res
		end
	end
end

sockethelper.readall = socket.readall

function sockethelper.writefunc(fd)
	return function(content)
		local s = assert(sockethelper.fds[fd])
		local ssl = s.ssl
		if ssl:ss() == ss.ss_connected then
			ssl:send(content)
		else
			error("state of ssl is not ss_connected")
		end
	end
end

function sockethelper.connect(host, port, timeout)
	local fd
	if timeout then
		local drop_fd
		local co = coroutine.running()
		-- asynchronous connect
		skynet.fork(function()
			fd = socket.open(host, port)
			if drop_fd then
				-- sockethelper.connect already return, and raise socket_error
				socket.close(fd)
			else
				-- socket.open before sleep, wakeup.
				skynet.wakeup(co)
			end
		end)
		skynet.sleep(timeout)
		if not fd then
			-- not connect yet
			drop_fd = true
		end
	else
		-- block connect
		fd = socket.open(host, port)
	end
	if fd then
		local c = {}

		function c.data(ssl, data, ... )
			-- body
			-- assert(false)
			local ssls = assert(sockethelper.ssls)
			local s   = assert(ssls[ssl])
			local res = assert(s.res)

			res = res .. data
			s.res = res
		end

		function c.write(ssl, content, ... )
			-- body
			print("write btytes:", #content)
			local ssls = assert(sockethelper.ssls)
			local s  = assert(ssls[ssl])
			local fd = assert(s.fd)
			if fd then
				local len = #content
				local ok = writebytes(fd, content)
				if not ok then
					error(socket_error)
				else
					return len
				end
			end
			return 0
		end

		function c.shutdown(ssl, how, ... )
			-- body
			local s  = assert(ssls[ssl])
			local fd = assert(s.fd)
		end

		function c.close(ssl, ... )
			-- body
			local s  = assert(ssls[ssl])
			local fd = assert(s.fd)

			socket.close(fd)
		end
		
		local ssl = ss.new(c)
		local s = {}
		s.ssl = ssl
		s.fd  = fd
		s.res = ""
		fds[fd]   = s
		ssls[ssl] = s

		ssl:connect(host, tonumber(port))
		while ssl:ss() ~= ss.ss_connected do
			socket.block(fd)
			local ret, extra = socket.read(fd)
			if ret then
				ssl:poll(ret)
			else
				ssl:poll(extra)
				break
			end
		end
	
		return fd
	end
	error(socket_error)
end

function sockethelper.close(fd)
	-- debug.debug()
	debug.traceback()
	local s = assert(fds[fd])
	local ssl = s.ssl
	ssl:close()
	-- socket.close(fd)
end

return sockethelper
