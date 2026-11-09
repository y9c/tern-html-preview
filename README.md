# HTML Preview (tern-html-preview)

Render `.html`/`.htm`/`.xhtml` files as a **real web page in a Tern browser
block** — full HTML, JavaScript and WebGL (3D), not a markdown or structural
view.

## Install

```sh
tern plugin install github.com/y9c/tern-html-preview
# or, while developing:
tern plugin link /tmp/tern-html-preview
```

## Use

Right-click an `.html` (or `.htm`/`.xhtml`) file and pick **Open with ›
HTML Preview**. The block serves the file's directory over a local HTTP
server (`127.0.0.1:8642`) and opens it in a browser block, which WebKit
renders (scripts/WebGL included).

## Requires

- **python3** (for `python3 -m http.server`).
- Port **8642** free (change `PORT` in `host.luau` if it isn't).

## How it works

- `host.luau` starts `python3 -m http.server <port> --bind 127.0.0.1
  --directory <dir>` and calls `cx:open("http://127.0.0.1:<port>/<file>")`.
- A `data:` URL did **not** route to a browser block (`cx:open` from a
  handler isn't routed), so a served `http://` URL is what reliably opens a
  browser block, which renders the page and runs its JavaScript/WebGL.

## Known limits

- **Local files only, cleanly.** The server runs on the machine that opens
  it. For a **remote** file, the server must run on that remote host (and the
  browser block loads the remote host's `http://` URL, port permitting).
- The server runs while the block is open; close the pane to stop it (best
  effort — there is no block “closed” handler).
- Serving exposes the file's **directory** on localhost, briefly.

## Remote hosts

Install the plugin and ensure `python3` is on the **remote host** too; the
host half serves the file there and the browser block loads its URL.
