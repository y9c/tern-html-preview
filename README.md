# HTML Preview (tern-html-preview)

Render `.html`/`.htm`/`.xhtml` files in a Tern block as **native Markdown**
via [pandoc](https://pandoc.org). No browser block, no HTTP server, no
hand-written parser.

## Install

```sh
tern plugin install github.com/y9c/tern-html-preview
# or, while developing:
tern plugin link /tmp/tern-html-preview
```

## Use

Right-click an `.html` (or `.htm`/`.xhtml`) file in the Files pane and pick
**Open with › HTML Preview**. The block converts the file with pandoc and
renders it with Tern's native `md` kind (headings, tables, lists, code,
links, images).

## How it works

- `host.luau` reads the file on its own host and runs
  `pandoc -f html -t markdown --wrap=none <path>` via `tern.process.run`.
- The output is drawn with `ui.md` — Tern's native Markdown renderer.
- Because the host half does the conversion, a **remote** file is converted
  on its own host (remote works when pandoc is installed there).

## Requires

- **pandoc** on the machine that hosts the file (the host half runs it).
  `brew install pandoc` on macOS. Not on PATH → you'll see a `pandoc failed`
  error view.

## Known limits

- Rendering fidelity is **Markdown's**, not a full browser's: complex
  layout, inline CSS and scripts are not reproduced.
- A very large file's `md` view may be heavy; pandoc itself is fast.

## Remote hosts

The block runs on the file's host (host half), so **remote files need the
plugin AND pandoc installed on that remote host**:

```sh
# in a pane on the remote host:
tern plugin install github.com/y9c/tern-html-preview
# and ensure pandoc is there
```
