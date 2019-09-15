local skynet = require "skynet"
local urllib = require "http.url"
local handler = require "web.handler"

local function route(ctx)
	if ctx.method == "GET" then
		local url = ctx.url
		local path, query = urllib.parse(url)
		ctx.path = path
		ctx.query = query
		local ok = pcall(handler.handle_get, ctx)
		if not ok then
			ctx.status = 404
			ctx.body = "404 Page"
		end
	elseif ctx.method == "POST" then
		ctx.request.body = body
		local ok = pcall(handler.handle_post, ctx)
		if not ok then
			ctx.status = 404
			ctx.body = "404 Page"
		end
	end
end

return {route = route}
