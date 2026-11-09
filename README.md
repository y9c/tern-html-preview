# HTML Preview (tern-html-preview)

Render `.html`/`.htm`/`.xhtml` files in a Tern **browser block**, instead of
opening them as plain syntax-highlighted source.

## Install

```sh
tern plugin install github.com/YOUR_USER/tern-html-preview
# or, while developing:
tern plugin link /path/to/tern-html-preview
```

## Use

Right-click an `.html` (or `.htm`/`.xhtml`) file in the Files pane and pick
**Open with › HTML Preview**. Tern starts the block, reads the file, and opens
a browser block rendering it as a page. The block pane shows a status line
with the path and byte count.

## How it works

- `host.luau` defines a `render` block that takes over `*.html`/`*.htm`
  (manifest `files`).
- On start it reads the file with `tern.fs.read`, base64-encodes it, and
  calls `cx:open("data:text/html;base64,…")` — Tern's browser block renders
  `data:` URLs, so **no temp file and no separate download step**.

## Remote hosts

For HTML files on a **remote** session: the block runs on the file's host, so
**install the plugin on that remote host too**:

```sh
# in a pane on the remote host:
tern plugin install github.com/YOUR_USER/tern-html-preview
```

Without it there, a routed open shows only an error toast.

## Known limits

- Tern's browser block **does not load remote sub-resources** (images, JS,
  CSS fetched from other hosts) — inline/same-page resources still work.
- The `data:`-URL browser-block path is the part that needs a run in your
  Tern to confirm (I could not run Tern here).

## Why not Rust
The Tern plugin **must be Luau** (`host.luau`/`window.luau`); a Rust binary
can only be an extra helper called via `tern.process.run`. For HTML the
rendering is already done by Tern's WebView-backed browser block, so a Rust
aid adds no rendering performance and forces users to build/install it
before `tern plugin install` works. If you later want a Rust helper (e.g.
HTML→text or a screenshot renderer), it would be a separate `cargo` binary
called from the block.
