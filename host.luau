--!strict
-- Render an HTML file as a real web page in a Tern browser block.
--
-- A browser block (WebView) is the only way to get full HTML + JS + 3D.
-- It loads a URL; a `data:` URL did not route there, so we serve the file's
-- directory over a local HTTP server (127.0.0.1) and open http://… in the
-- browser block, which WebKit then renders (scripts, WebGL included).

local ui = tern.ui
local fs = tern.fs

local PORT = 8642 -- fixed; change if your env occupies it

type State = {
	path: string,
	dir: string,
	name: string,
	serving: boolean,
	err: string?,
	serverPid: number?,
}

local block = {
	init = function(cx, args, _saved)
		local path = args[1] or ""
		local dir, name = path:match("^(.*)/([^/]+)$")
		local state: State = {
			path = path,
			dir = dir or ".",
			name = name or path,
			serving = true,
			err = nil,
			serverPid = nil,
		}
		if path == "" or not name then
			state.err = "HTML Preview: no file given"
			state.serving = false
			return state
		end
		if not fs.exists(path) then
			state.err = "HTML Preview: no such file " .. path
			state.serving = false
			return state
		end

		-- Serve the file's directory on localhost, then open the URL in a
		-- browser block. The server must stay up while the page is viewed.
		local ok, err = pcall(function()
			tern.process.run(
				{ "python3", "-m", "http.server", tostring(PORT), "--bind", "127.0.0.1", "--directory", state.dir },
				{ cwd = state.dir, timeout_ms = 0 },
				function(r)
					-- Long-running server: a nonzero exit means it stopped.
					if cx ~= nil then
						cx:toast("warning", "HTML Preview server stopped", tostring(r.status))
					end
				end
			)
		end)
		if not ok then
			state.err = "HTML Preview: could not start server (" .. tostring(err) .. ")"
			state.serving = false
		end

		-- Open the served URL in a browser block.
		local url = "http://127.0.0.1:" .. tostring(PORT) .. "/" .. state.name
		cx:open(url)
		return state
	end,

	title = function(state)
		return "HTML: " .. state.name
	end,

	view = function(state, _cx)
		if state.err then
			return { main = ui.col({ ui.text({ ui.span(state.err, "error") }) }) }
		end
		return {
			main = ui.col({
				ui.text({ ui.span("Served " .. state.name .. " at http://127.0.0.1:" .. tostring(PORT), "success") }),
				ui.text({ ui.span("Close this pane when done; the local server stops with it.", "muted") }),
			}),
		}
	end,
}

tern.block.define("render", block)
