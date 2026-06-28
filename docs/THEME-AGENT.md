# Theme agent guide

Audience: the agent that creates and maintains **themes** (and now **layouts**)
for lazysite - both developing them in this repo and managing them on a live
site through the connector (MCP), WebDAV, or the control API.

If you only need the packaging/processor contract, see
`PROCESSOR-INTEGRATION.md`. This guide is the day-to-day theme-author view.

## What changed (2026-06-28)

- **Theme shape is unchanged**: `theme.json` (with `layouts[]`) + `assets/main.css`.
- **Layouts are now theme-agnostic.** Every layout's `layout.tt` uses the portable
  `[% theme_assets %]/main.css` link instead of a hardcoded
  `/lazysite-assets/<layout>/<theme>/main.css`. Consequence: **a layout works with
  any of its themes, so multiple themes per layout are now supported** (before,
  each layout was effectively locked to its like-named theme).
- **`layout.json` gained `default_theme`** (and an informational `themes[]`).
- **The repo ships a catalogue**: root `manifest.json` + `releases/layouts/<L>.zip`
  alongside the existing `releases/<L>/<T>.zip`. All built by
  `./tools/package-themes.sh`.
- **On a site**, the manager "Themes" page is now **Appearance**. You can install
  one layout + its theme(s) on demand, delete a layout, switch the active
  layout/theme, and preview a theme from a different layout (CSS now resolves).

## Developing a theme (in THIS repo)

A theme lives at `layouts/<LAYOUT>/themes/<THEME>/`:

```
theme.json        name, version, layouts: ["<LAYOUT>"], config { colours, fonts, ... }
assets/main.css   the web-served stylesheet (+ any other assets/)
```

- **`theme.json.layouts[]` must include the layout it sits under.** Install and
  activate reject a theme that doesn't, and the manifest won't list it.
- **A second theme for a layout** is just another theme dir whose
  `theme.json.layouts[]` names that layout - the layout's `[% theme_assets %]`
  link loads whichever is active.
- **A new layout**: `layouts/<L>/layout.tt` (use `[% theme_assets %]/main.css`,
  never hardcode) + `layouts/<L>/layout.json` (`name`, `version`, `description`,
  `author`, `default_theme`), plus at least one theme.
- **After any change**: run `./tools/package-themes.sh` (rebuilds theme + layout
  zips and `manifest.json`), then commit `releases/` + `manifest.json`. Push to
  the branch the target sites read (`layouts_ref`, default `main`) before it can
  be installed.

`config` tokens become CSS custom properties the layout/theme reference; copy an
existing theme (e.g. `nova`, `default/*`) as a starting point.

## Managing themes/layouts on a LIVE site

Themes are **developed in this repo** and **deployed to a site** by installing
them from the manifest - the repo is the source of truth. Three programmatic
surfaces, all gated by the partner's capabilities (introspect with `whoami`):

### MCP connector (preferred for an AI agent)

| Tool | Use |
|------|-----|
| `whoami` | your capabilities + the active layout/theme |
| `list_themes` | installed themes across all layouts (+ which is active) |
| `list_layout_catalogue` *(new)* | what the repo manifest offers: layouts -> themes, versions, and an `installed` flag |
| `install_layout` *(new)* | install a layout + its theme(s) on demand (default theme, a specific `theme`, or `all:true`) and activate; mirrors assets, clears cache |
| `activate_layout` / `activate_theme` | switch the active layout / theme |
| `delete_layout` *(new)* | remove a layout AND its themes (never the active one; a snapshot is kept) |
| `invalidate_cache` | clear the HTML cache |
| `preview_page`, `read_page`, `write_file`, `replace_text`, `list_files` | author/inspect content |

`install_layout` / `delete_layout` / `activate_*` need the **`manage_layouts`**
capability; `list_*` / `activate_theme` accept `manage_themes` too.

### Control API (bearer token) - `/cgi-bin/lazysite-manager-api.pl`

The same operations over HTTP with a token, capability-gated. New / relevant
actions:

- `layouts-manifest`, `layout-install`, `layout-delete` *(new; `manage_layouts`)*
- `layout-activate`, `theme-activate`, `themes-list-all`, `themes-for-layout`,
  `layouts-available`
- `theme-upload` / `theme-delete` / `theme-rename` stay **operator-cookie only** -
  develop theme source in this repo (then `install_layout`), not via these.

### WebDAV (`lazysite-dav.pl`)

File-level read/write to the published tree per your ACL - for **site content**.
The active layout/theme directories are write-locked; theme *source* lives here in
the repo, so prefer repo + `install_layout` over writing theme files onto a site.

## Gotchas

- A new theme for an existing layout must name that layout in `theme.json.layouts[]`.
- Never hardcode `/lazysite-assets/...` in `layout.tt` - use `[% theme_assets %]`.
- `install_layout` only sees what's on `layouts_ref` (default `main`) of
  `layouts_repo` - push/merge repo changes (or set `layouts_ref`) first.
- After editing themes, re-run `./tools/package-themes.sh` so the manifest matches.
