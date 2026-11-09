--!strict
-- Render an HTML file as native Tern Markdown, via pandoc.
--
-- The host half reads the file on its own host (remote files work when
-- pandoc is on that host) and converts HTML → Markdown; the block renders it
-- with Tern's native `md` kind. No browser block, no HTTP server, no
-- hand-written parser. Pandoc is robust for arbitrary/well-formed HTML.

local ui = tern.ui

type State = {
	path: string,
	markdown: string?,
	converting: boolean,
	err: string?,
}

local block = {
	init = function(cx, args, _saved)
		local path = args[1] or ""
		local state: State = { path = path, markdown = nil, converting = false, err = nil }
		if path == "" then
			state.err = "HTML Preview: no file given"
			return state
		end

		state.converting = true
		tern.process.run(
			{ "pandoc", "-f", "html", "-t", "markdown", "--wrap=none", path },
			{ cwd = cx.cwd, timeout_ms = 30000 },
			function(r)
				if r.status == 0 then
					state.markdown = r.stdout or ""
					state.err = nil
				else
					local detail = (r.stderr or ""):gsub("%s+", " "):sub(1, 160)
					state.err = "HTML Preview: pandoc failed (" .. tostring(r.status) .. ")" ..
						(if #detail > 0 then " " .. detail else "")
				end
				state.converting = false
				cx:render()
			end
		)
		return state
	end,

	title = function(state)
		return "HTML: " .. state.path
	end,

	view = function(state, _cx)
		if state.err then
			return { main = ui.col({ ui.text({ ui.span(state.err, "error") }) }) }
		end
		if state.converting or state.markdown == nil then
			return { main = ui.col({ ui.text({ ui.span("Converting HTML → Markdown…", "muted") }) }) }
		end
		if state.markdown == "" then
			return { main = ui.col({ ui.text({ ui.span("(no text content)", "muted") }) }) }
		end
		return { main = ui.col({ ui.md(state.markdown) }) }
	end,
}

tern.block.define("render", block)
