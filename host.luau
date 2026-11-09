--!strict
-- Render an HTML file as a real web page in a Tern browser block, using a
-- TEMPORARY local server: the port opens while the block is up and is
-- stopped when the block's pane goes away (there is no block “closed”
-- callback, so we poll tern.pane.list() and kill the server).

local ui = tern.ui

local PORT = 8642 -- change if occupied

type State = {
	path: string,
	name: string,
	dir: string,
	serving: boolean,
	err: string?,
}

local function paneAlive(id: number): boolean
	for _, p in tern.pane.list() do
		if p.pane == id then
			return true
		end
	end
	return false
end

local block = {
	init = function(cx, args, _saved)
		local path = args[1] or ""
		local dir, name = path:match("^(.*)/([^/]+)$")
		local state: State = {
			path = path,
			name = name or path,
			dir = dir or ".",
			serving = true,
			err = nil,
		}
		if path == "" or not name then
			state.err = "HTML Preview: no file given"
			state.serving = false
			return state
		end

		local ok, err = pcall(function()
			tern.process.run(
				{ "python3", "-m", "http.server", tostring(PORT), "--bind", "127.0.0.1", "--directory", state.dir },
				{ cwd = state.dir, timeout_ms = 0 },
				function(r)
					cx:toast("warning", "HTML Preview server exited", tostring(r.status))
				end
			)
		end)
		if not ok then
			state.err = "HTML Preview: could not start server (" .. tostring(err) .. ")"
			state.serving = false
			return state
		end

		-- Watchdog: stop the server when this block's pane is gone.
		local pane_id = cx.pane
		local stopped = false
		local function watchdog()
			if stopped then
				return
			end
			if not paneAlive(pane_id) then
				stopped = true
				tern.process.run({ "pkill", "-f", "http.server " .. tostring(PORT) }, {}, function() end)
				return
			end
			tern.timer(1000, watchdog)
		end
		tern.timer(1000, watchdog)

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
				ui.text({ ui.span("Serving " .. state.name .. " at http://127.0.0.1:" .. tostring(PORT), "success") }),
				ui.text({ ui.span("Temporary: the port closes when this block closes.", "muted") }),
			}),
		}
	end,
}

tern.block.define("render", block)
