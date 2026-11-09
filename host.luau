--!strict
-- The `render` block: renders an HTML file in a Tern browser block.
--
-- The file path arrives as the block's first launch argument ("Open with
-- › HTML Preview", matched by the manifest `files` globs), with `cx.cwd`
-- set to the file's folder.
--
-- Design: read the file (on the host that owns it — local, or the remote
-- host for a remote pane), then open it in a browser block via a `data:`
-- URL. Tern's browser block renders `data:` URLs, so the content crosses
-- from a possibly-remote host to the local window that draws it, with no
-- temp file and no separate download step.

local ui = tern.ui
local fs = tern.fs

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Standard base64 for a byte string (padded). Luau supports bitwise ops.
local function base64(s: string): string
	local chunks: { string } = {}
	local i = 1
	local len = #s
	while i <= len do
		local b1 = string.byte(s, i)
		local b2 = string.byte(s, i + 1) or 0
		local b3 = string.byte(s, i + 2) or 0
		-- 6-bit groups via integer division and modulo (no bitwise ops,
		-- which some Luau builds reject).
		local c1 = (b1 // 4) + 1
		local c2 = ((b1 % 4) * 16 + b2 // 16) + 1
		local c3 = ((b2 % 16) * 4 + b3 // 64) + 1
		local c4 = (b3 % 64) + 1
		local part = B64:sub(c1, c1) .. B64:sub(c2, c2)
		part = part .. (if i + 1 <= len then B64:sub(c3, c3) else "=")
		part = part .. (if i + 2 <= len then B64:sub(c4, c4) else "=")
		chunks[#chunks + 1] = part
		i = i + 3
	end
	return table.concat(chunks)
end

type State = {
	path: string,
	err: string?,
	bytes: number?,
}

-- Resolve args[1] against `cx.cwd` when it is relative (`tern.fs` resolves
-- relative paths against the plugin's own folder, not the pane's).
local function resolve(path: string, cwd: string?): string
	if path == "" then
		return path
	end
	if path:sub(1, 1) == "/" or path:match("^%a:/") then
		return path
	end
	if cwd and cwd ~= "" then
		return cwd .. "/" .. path
	end
	return path
end

local block = {
	init = function(cx, args, _saved)
		local path = resolve(args[1] or "", cx.cwd)
		local state: State = {
			path = path,
			err = nil,
			bytes = nil,
		}

		local ok, content = pcall(fs.read, path)
		if ok and type(content) == "string" then
			state.bytes = #content
			-- Open the content in a browser block as a data: URL.
			local url = "data:text/html;base64," .. base64(content)
			cx:open(url)
		else
			state.err = "HTML Preview: could not read " .. path
		end
		return state
	end,

	title = function(state)
		return "HTML: " .. state.path
	end,

	view = function(state, _cx)
		if state.err then
			return { main = ui.col({ ui.text({ ui.span(state.err, "error") }) }) }
		end
		return {
			main = ui.col({
				ui.text({ ui.span("Rendered as a browser block", "success") }),
				ui.text({ ui.span(state.path .. "  (" .. tostring(state.bytes or 0) .. " bytes)", "muted") }),
			}),
		}
	end,
}

tern.block.define("render", block)
