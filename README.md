# HTML Preview (tern-html-preview)

Render `.html`/`.htm`/`.xhtml` files in a Tern block using Tern's **native
`el` HTML elements** — a structural view (headings, paragraphs, lists,
tables, code, strong/em), read and rendered by the host half. No browser
block, no HTTP server, no LibreOffice.

## Install

```sh
tern plugin install github.com/y9c/tern-html-preview
# or, while developing:
tern plugin link /tmp/tern-html-preview
```

## Use

Right-click an `.html` (or `.htm`/`.xhtml`) file in the Files pane and pick
**Open with › HTML Preview**. Tern reads the file and draws it as native
`el` elements in a block.

## Why `el` (native, remote-capable)

- Tern's `el` draws real HTML tags inside Tern's own pane, so the view is
  rendered natively (not via a browser block or a served URL).
- The block is defined in the host half, so a **remote** file is read on its
  own host (like `jsonx` reads remote JSON) — no HTTP server, no download.
- `el` supports a fixed tag list; `text` becomes child text nodes.

## Known limits

- **Structural, not a faithful webpage**: Tern's `el` has **no** `<img>`,
  `<a>`, `<textarea>` or `<select>`; `style`, `id`, `src`, `onclick` are
  ignored; no JavaScript runs. So images, links, inline CSS and scripts are
  dropped (link text is kept as plain text; images are omitted).
- Best-effort walk: entities (`&amp;`) are not decoded; malformed HTML can
  mis-nest. Swap in a real parser if you need faithful output.
- Files over 2 MiB are refused rather than streamed.

## Remote hosts

The block runs on the file's host (host half), so **remote files need the
plugin installed on that remote host too**:

```sh
# in a pane on the remote host:
tern plugin install github.com/y9c/tern-html-preview
```

Without it there, an open shows only an error toast.

## Why not Rust

The Tern plugin **must be Luau**; a Rust binary can only be an extra helper
called via `tern.process.run`. For native HTML structure rendering (`el`)
neither a browser nor a server is involved, so Rust adds no rendering
benefit here.
