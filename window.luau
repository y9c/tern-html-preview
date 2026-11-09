--!strict
-- Render .html/.htm files in a browser block, via a temporary local server.
--
-- A browser block loads a URL; a host block's `cx:open` is NOT routed (it
-- cannot open a browser block). So we intercept file opens in the WINDOW
-- half with tern.route.open, start a local http server, and return
-- `{ url = … }`, which Tern follows to a browser block.

local PORT = 8642
local started = false

tern.route.open(function(req, _cx)
	-- Only HTML files, from the Files pane or the palette, default placement.
	if not (string.match(req.path, "%.html?$") or string.match(req.path, "%.htm$") or string.match(req.path, "%.xhtml$")) then
		return nil
	end
	if req.origin ~= "files" and req.origin ~= "palette" then
		return nil
	end
	if req.how ~= "default" then
		return nil
	end

	local dir, name = req.path:match("^(.*)/([^/]+)$")
	if not dir then
		return nil
	end

	-- Start the server once (first file's directory). Best-effort.
	if not started then
		pcall(function()
			tern.process.run(
				{ "python3", "-m", "http.server", tostring(PORT), "--bind", "127.0.0.1", "--directory", dir },
				{ timeout_ms = 0 },
				function() end
			)
		end)
		started = true
	end

	return { url = "http://127.0.0.1:" .. tostring(PORT) .. "/" .. name }
end)
