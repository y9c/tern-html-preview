--!strict
-- Render an HTML file as native Tern elements (`el`) in the block.
--
-- Why `el`: it draws real HTML tags inside Tern's own pane, so the view is
-- native and the content is read by the HOST half — a remote file is read on
-- its own host (like jsonx), so remote works with no HTTP server and no
-- browser block. Tern's `el` allows a fixed tag list and no
-- <img>/<a>/inline CSS/JS, so this is a STRUCTURAL view (headings,
-- paragraphs, lists, tables, code, strong/em), not a faithful webpage.

local ui = tern.ui
local fs = tern.fs

-- Tags we drop as noise (their text is kept when it reaches the parent).
local SKIP: { [string]: boolean } = {
	script = true,
	style = true,
	head = true,
	template = true,
	noscript = true,
	title = true,
	meta = true,
	link = true,
	img = true,
	a = true,
	input = true,
	textarea = true,
	select = true,
	button = true,
	form = true,
}

type N = {
	tag: string?,
	text: string,
	children: { N },
}

-- Best-effort HTML walk for v0.1. Text becomes child nodes (order kept);
-- whitespace-only text is dropped; unsupported tags are skipped (their text
-- accumulates on the parent). Entities are not decoded.
local function parse(body: string): { N }
	local roots: { N } = {}
	local stack: { N } = {}
	local count = 0
	local stopped = false

	local function push(node: N)
		if stopped then
			return
		end
		count = count + 1
		if count > MAX_NODES then
			stopped = true
			return
		end
		if #stack > 0 then
			stack[#stack].children[#stack[#stack].children + 1] = node
		else
			roots[#roots + 1] = node
		end
	end

	local function textNode(txt: string)
		if #txt > 0 and txt:match("%S") then -- drop whitespace-only
			push({ tag = nil, text = txt, children = {} })
		end
	end

	local i = 1
	local n = #body
	while i <= n do
		local lt = string.find(body, "<", i, true)
		if not lt then
			textNode(body:sub(i))
			break
		end
		if lt > i then
			textNode(body:sub(i, lt - 1))
		end
		local gt = string.find(body, ">", lt, true)
		if not gt then
			textNode(body:sub(lt))
			break
		end
		local raw = body:sub(lt, gt)
		i = gt + 1
		local isClose = string.sub(raw, 2, 2) == "/"
		local name = string.match(raw, "^%s*<?/?(%a[%w%-]*)")
		if name then
			name = string.lower(name)
			if isClose then
				-- pop to the nearest matching open tag
				for idx = #stack, 1, -1 do
					if stack[idx].tag == name then
						while #stack >= idx do
							table.remove(stack)
						end
						break
					end
				end
			else
				local selfClose = string.match(raw, "/%s*>%s*$") ~= nil
				if not SKIP[name] then
					local node: N = { tag = name, text = "", children = {} }
					push(node)
					if not selfClose and name ~= "br" and name ~= "hr" then
						stack[#stack + 1] = node
					end
				end
			end
		end
		if stopped then
			break
		end
	end
	return roots, stopped
end

-- Convert a parsed node to an `el`/`text` node.
local function toEl(node: N): any
	if node.tag == nil then
		return ui.text({ node.text })
	end
	local children: { any } = {}
	for _, c in ipairs(node.children) do
		children[#children + 1] = toEl(c)
	end
	return ui.el(node.tag, {}, children)
end

local MAX_BYTES = 4 * 1024 * 1024
local MAX_NODES = 15000

type State = { path: string, nodes: { N }?, err: string?, truncated: boolean? }

local block = {
	init = function(cx, args, _saved)
		local path = args[1] or ""
		local state: State = { path = path, nodes = nil, err = nil }
		if path == "" then
			state.err = "HTML Preview: no file given"
		end
		if not state.err then
			local ok, content = pcall(fs.read, path)
			if not ok then
				state.err = "HTML Preview: could not read " .. path
			elseif #content > MAX_BYTES then
				state.err = "HTML Preview: file too large (" .. tostring(#content) .. " bytes; limit 4 MiB)"
			else
				local okp, nodes, stopped = pcall(parse, content)
				if okp then
					state.nodes = nodes
					state.truncated = stopped == true
				else
					state.err = "HTML Preview: parse error"
				end
			end
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
		local content: { any } = {}
		if state.truncated then
			content[#content + 1] = ui.text({ ui.span("… truncated at " .. MAX_NODES .. " elements", "warning") })
		end
		for _, node in ipairs(state.nodes or {}) do
			content[#content + 1] = toEl(node)
		end
		if #content == 0 then
			return { main = ui.col({ ui.text({ ui.span("(empty or unsupported HTML)", "muted") }) }) }
		end
		return { main = ui.col(content) }
	end,
}

tern.block.define("render", block)
