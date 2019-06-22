local skynet = require "skynet"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"
local handler = require "gm.web.handler"

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local function route( id, code, url, method, header, body )
	-- body
	if method == "GET" then
		local path, query = urllib.parse(url)
		local ok, statuscode, headerd, bodyfunc = handler.handle_static(code, path, header)
		if ok then
			for k,v in pairs(header) do
				headerd[k] = v
			end
			response(id, statuscode, bodyfunc, headerd)
			return
		else
			ok, statuscode, headerd, bodyfunc = handler.handle_get(code, path, query, header)
			if ok then
				for k,v in pairs(header) do
					headerd[k] = v
				end
				response(id, statuscode, bodyfunc, headerd)
				return
			else
				bodyfunc = "404 Page"
				response(id, 404, bodyfunc, header)
				return
			end
		end
	elseif method == "POST" then
		local ok, statuscode, headerd, bodyfunc = handler.handle_file(code, path, header)
		if ok then
			for k,v in pairs(header) do
				headerd[k] = v
			end
			response(id, statuscode, bodyfunc, headerd)
			return
		else
			ok, statuscode, headerd, bodyfunc = handler.handle_post(code, path, query, header)
			if ok then
				for k,v in pairs(header) do
					headerd[k] = v
				end
				response(id, statuscode, bodyfunc, headerd)
				return
			else
				bodyfunc = "404 Page"
				response(id, 404, bodyfunc, header)
				return
			end
		end
	end
end 

return { route = route }