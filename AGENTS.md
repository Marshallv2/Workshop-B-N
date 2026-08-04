# AGENTS.md

## Cursor Cloud specific instructions

This repo is a **static, dependency-free web app** — there is no package manager, no build step, no backend, and no automated test/lint tooling. The deliverables are the HTML files themselves (`index.html` and `workshop-kanalstandard.html`), each fully self-contained with inline CSS/JS.

### Services

There is only one "service": a static file server for the HTML. Run it from the repo root and open the page in a browser:

```
python3 -m http.server 8000
# then open http://localhost:8000/index.html
```

`index.html` is the main workshop tool (editable AutoCAD layer table, filter/search, save, export). `workshop-kanalstandard.html` is a standalone companion page. Both can also be opened directly via `file://`, but serving over HTTP better mirrors real usage.

### Non-obvious notes

- **`index.html` loads SheetJS from a CDN** (`https://cdn.sheetjs.com/xlsx-0.20.3/...`, see line ~7). The **"Excel exportieren (.xlsx)"** feature needs outbound internet access to that CDN. All other functionality (editing, filtering, CSV export, browser save) works fully offline. `workshop-kanalstandard.html` has no external dependencies.
- **State persistence is per-browser `localStorage`** (key set in `index.html`). "Speichern (Browser)" saves and "Laden" restores; there is no server-side storage, so state does not sync across browsers/machines.
- **No lint/test/build commands exist.** Testing is manual/in-browser. Do not attempt to run `npm`, `pnpm`, `pip`, etc. — there are no manifests/lockfiles.
