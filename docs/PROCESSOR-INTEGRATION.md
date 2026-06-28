# Handover: packaging + processor integration

Status: implemented on branch `claude/statement-themes` (this branch). The
lazysite processor now installs a **single layout and its theme(s) on demand**
from a `manifest.json` + per-package zips. This note explains what changed here,
the contract the processor depends on, and what you (the layouts agent) must do
going forward.

## 1. What changed in this repo

All on `claude/statement-themes`:

1. **`layout.json` gained `themes[]` + `default_theme`** (all 22 layouts).
   `default_theme` is the theme activated when a user installs the layout without
   choosing one. `themes[]` is an informational forward index (the manifest is
   derived from the theme dirs, not from this field - see §3).
2. **`layout.tt` uses the portable asset link** (all 21 that were hardcoded are
   migrated). The CSS link is now
   `[% IF theme_assets %]<link rel="stylesheet" href="[% theme_assets %]/main.css">[% END %]`
   instead of `/lazysite-assets/<layout>/<layout>/main.css`. This lets a layout
   load whichever theme is active and fixes cross-theme preview.
3. **`tools/package-layouts.sh`** - builds `releases/layouts/<L>.zip`
   (`layout.tt` + `layout.json` only; no `themes/`).
4. **`tools/gen-manifest.pl`** - writes a canonical `manifest.json` (schema 1) at
   the repo root, enumerating layouts -> themes with versions and repo-relative
   package paths.
5. **`tools/package-themes.sh`** now calls `package-layouts.sh` at the end, so a
   single run produces theme zips + layout zips + `manifest.json`, always
   consistent.
6. **`releases/layouts/*.zip` and `manifest.json`** are committed.

## 2. The contract the processor relies on - don't break these

- **`manifest.json` at the repo root**, fetched as a raw file on the read ref
  (see §4). Schema:

  ```json
  {
    "schema": 1,
    "generated": "YYYY-MM-DD",
    "layouts": [
      { "name": "nova", "version": "1.0.0",
        "package": "releases/layouts/nova.zip",
        "default_theme": "nova",
        "themes": [ { "name": "nova", "version": "1.0.0",
                      "package": "releases/nova/nova.zip" } ] }
    ]
  }
  ```

- **Layout package** `releases/layouts/<L>.zip` = `layout.tt` + `layout.json` at
  the zip root, nothing else.
- **Theme package** `releases/<L>/<T>.zip` = `theme.json` at root + `assets/`
  subtree (unchanged shape).
- **`theme.json.layouts[]` must include the layout** the theme sits under. The
  processor validates this at install and activate; `gen-manifest.pl` only lists
  a theme for a layout when its `theme.json.layouts[]` names that layout.
- **`layout.tt` must use `[% theme_assets %]/main.css`**, never a hardcoded
  `/lazysite-assets/.../main.css`. A hardcoded path 404s for any theme whose name
  differs from the layout, and breaks preview.
- **`layout.json.default_theme`** should name a real theme; the processor
  installs it when the user installs the layout without choosing a theme.

## 3. Ongoing tasks (your job)

The golden rule: **after any add or edit of a layout or theme, run
`./tools/package-themes.sh` and commit the changed `releases/` + `manifest.json`.**
The manifest is derived from the theme dirs on disk, so it cannot drift as long
as you re-run the build.

- **New layout**: create `layouts/<L>/layout.tt` (portable assets link) and
  `layouts/<L>/layout.json` (`name`, `version`, `description`, `author`,
  `default_theme`). Add at least one theme (below). Run the build.
- **New theme for a layout**: create `layouts/<L>/themes/<T>/theme.json`
  (`layouts: ["<L>"]`, `config`, `version`) + `assets/main.css`. Run the build -
  the manifest picks it up automatically, and because the layout uses
  `[% theme_assets %]` the new theme's CSS loads when activated. Multi-theme
  layouts now work.
- **Version bumps**: bump `layout.json.version` / `theme.json.version` on changes;
  the manifest carries them so the processor can offer update-in-place later.

## 4. Distribution / which ref the processor reads

The processor fetches `manifest.json` and the package zips as **raw files** from
`https://raw.githubusercontent.com/<repo>/<ref>/...`, where `<ref>` is
`layouts_ref` in the site's `lazysite.conf` (**default `main`**). So:

- **Merge this branch to `main`** (the default read ref) for live installs to
  work, OR set `layouts_ref: claude/statement-themes` on a test site to try it
  before merge.
- These changes are currently only **local on this host** on
  `claude/statement-themes` - GitHub does not have `manifest.json` until you
  push/merge.

Verify once pushed (raw must return the manifest):

```
curl -fsSL https://raw.githubusercontent.com/OpenDigitalCC/lazysite-layouts/main/manifest.json | head
```

(substitute the branch for `main` if testing pre-merge).

## 5. Note

Layout **upload** in the manager UI is theme-only today; layouts install from the
catalogue (this manifest). If layout upload is wanted, the processor needs an
`action_layout_upload`; flag it and it can be added.
