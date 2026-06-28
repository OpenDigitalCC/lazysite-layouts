# Proposal: packaging layouts and downloading layout + associated themes

Status: draft for processor implementation
Audience: lazysite core (processor / manager) maintainer
Repo: `OpenDigitalCC/lazysite-layouts`

## Purpose

Today the processor can install **themes** from this repo, but
**layouts** are a manual copy. With 21 of the 26 themes now
shipping their own dedicated layout (one theme per layout), the
manual step is the bottleneck: a user who picks `nova` from the
gallery cannot use it until someone hand-copies `nova/layout.tt`
and `nova/layout.json` onto the server.

This document specifies the packaging and metadata changes this
repo will make, and the corresponding processor changes needed so
that **installing a layout also pulls its associated theme(s)** in
one operation.

It is a spec for *both sides*: section 3 is what this repo will
ship; section 4 is what the processor must do with it.

---

## 1. Current state

### 1.1 What this repo ships today

```
layouts/
  <LAYOUT>/
    layout.tt            structural HTML template (TT)
    layout.json          metadata: name, version, description, author
    themes/
      <THEME>/
        theme.json       metadata + config tokens + layouts[]
        assets/
          main.css       the only web-served asset
releases/
  <LAYOUT>/
    <THEME>.zip          theme package (theme.json at root + assets/)
tools/
  package-themes.sh      walks layouts/*/themes/*/ -> releases/*/*.zip
```

- **Themes are packaged.** `tools/package-themes.sh` produces one
  zip per theme at `releases/<LAYOUT>/<THEME>.zip`, in the D013
  upload shape (`theme.json` at zip root, `assets/` subtree).
- **Layouts are NOT packaged.** `layout.tt` / `layout.json` are
  installed by manual copy (see README "Installing > Layout").
- **There is no top-level manifest.** Nothing enumerates the set
  of layouts, or maps a layout to its themes, in a single file.

### 1.2 What the processor does today

Per the README, with `layouts_repo: OpenDigitalCC/lazysite-layouts`
set in `lazysite.conf`, the manager's "Install from Releases"
downloads a **theme** zip and installs it under the **active**
layout. It assumes the layout already exists.

### 1.3 Install targets on the server (D013)

```
{DOCROOT}/lazysite/layouts/<LAYOUT>/layout.tt
{DOCROOT}/lazysite/layouts/<LAYOUT>/layout.json
{DOCROOT}/lazysite/layouts/<LAYOUT>/themes/<THEME>/theme.json
{DOCROOT}/lazysite/layouts/<LAYOUT>/themes/<THEME>/assets/...
{DOCROOT}/lazysite-assets/<LAYOUT>/<THEME>/...   <- web-served mirror of assets/
```

`theme.json` lives in the web-blocked theme dir (read by the
processor on load). Only the `assets/` subtree is mirrored to
the public `/lazysite-assets/<LAYOUT>/<THEME>/` path, which is
what `[% theme_assets %]` resolves to.

---

## 2. The two gaps to close

1. **No layout package.** The processor has nothing to download
   for the layout itself.
2. **No layout -> theme association the processor can read.** The
   binding exists only in the *reverse* direction
   (`theme.json.layouts[]`), and only inside each theme zip, which
   the processor would have to download and open to discover. There
   is no forward index ("layout `nova` has themes `[nova]`").

A third, softer gap (see 5.3): most new layouts **hardcode** the
theme asset path, so a layout currently resolves correctly only
with the single theme whose name equals the layout name.

---

## 3. What this repo will ship (packaging changes)

### 3.1 Layout packages

Add a layout package alongside the theme packages:

```
releases/
  layouts/
    <LAYOUT>.zip
```

Zip shape (layout-only — no theme inside):

```
<LAYOUT>.zip
  layout.tt
  layout.json
```

Rationale for a sibling `releases/layouts/` directory (rather than
nesting layout zips under `releases/<LAYOUT>/`): keeps the layout
package discoverable by a single fixed prefix and avoids any
ambiguity with the per-layout theme directories that already exist
at `releases/<LAYOUT>/`.

A second tool, `tools/package-layouts.sh` (or an extension of the
existing script), walks `layouts/*/` and zips each layout's
`layout.tt` + `layout.json`. It must **not** include `themes/`.

### 3.2 `layout.json` gains a `themes[]` association

`layout.json` today has only `name/version/description/author`.
Add a forward association and a default:

```json
{
  "name": "nova",
  "version": "1.0.0",
  "description": "NOVA statement layout ...",
  "author": "OpenDigitalCC",
  "themes": ["nova"],
  "default_theme": "nova"
}
```

- `themes[]` — names of themes in this repo that target this
  layout. Authoritative forward index; mirrors the union of every
  `theme.json.layouts[]` that names this layout.
- `default_theme` — which theme to activate if the user installs
  the layout without choosing a theme. For the single-theme
  layouts this is the one theme; for `default` it is `default`.

These two fields are the minimum the processor needs to resolve
"download layout + associated themes" without opening every theme
zip first.

### 3.3 A top-level manifest

Generate `manifest.json` at the repo root, regenerated by the
packaging tool so it can never drift from the zips on disk:

```json
{
  "schema": 1,
  "generated": "2026-06-28",
  "layouts": [
    {
      "name": "default",
      "version": "1.0.0",
      "package": "releases/layouts/default.zip",
      "default_theme": "default",
      "themes": [
        { "name": "default",  "version": "1.0.0", "package": "releases/default/default.zip" },
        { "name": "dark",     "version": "1.0.0", "package": "releases/default/dark.zip" },
        { "name": "studio",   "version": "1.0.0", "package": "releases/default/studio.zip" },
        { "name": "warm",     "version": "1.0.0", "package": "releases/default/warm.zip" },
        { "name": "terminal", "version": "1.0.0", "package": "releases/default/terminal.zip" }
      ]
    },
    {
      "name": "nova",
      "version": "1.0.0",
      "package": "releases/layouts/nova.zip",
      "default_theme": "nova",
      "themes": [
        { "name": "nova", "version": "1.0.0", "package": "releases/nova/nova.zip" }
      ]
    }
  ]
}
```

With `manifest.json` the processor does **one** fetch to learn the
entire catalogue: every layout, its package URL, its themes, and
each theme's package URL. No GitHub API crawl, no opening zips to
discover bindings.

Each entry also carries `version`, so the processor can offer
update-in-place (compare installed `layout.json.version` /
`theme.json.version` against the manifest).

### 3.4 Tooling

- Extend/replace `tools/package-themes.sh` so a single run:
  1. builds `releases/<LAYOUT>/<THEME>.zip` (unchanged),
  2. builds `releases/layouts/<LAYOUT>.zip` (new),
  3. writes `manifest.json` from what it just built (new).
- Keep the existing caveat in mind: the script does
  `rm -rf releases` and rebuilds everything, so all zips re-emit
  with new mtimes (byte-churn) on every run. Generating the
  manifest in the same pass guarantees manifest/zip consistency
  per commit.

---

## 4. What the processor must do (the new install flow)

Goal: "install layout X" pulls the layout **and** its associated
theme(s), installs both, mirrors assets, and activates.

### 4.1 Resolve

1. Fetch `manifest.json` from the configured `layouts_repo`
   (raw file on the chosen ref/tag, or the release asset).
2. Locate the requested layout entry. From it the processor now
   knows: the layout package URL, the theme list with package
   URLs, and `default_theme`.

### 4.2 Download + install the layout

3. Download `releases/layouts/<LAYOUT>.zip`.
4. Extract to `{DOCROOT}/lazysite/layouts/<LAYOUT>/` →
   `layout.tt`, `layout.json`.

### 4.3 Download + install the associated theme(s)

For each theme to install (either all of `themes[]`, or just the
user's pick, or `default_theme`):

5. Download `releases/<LAYOUT>/<THEME>.zip`.
6. Extract to
   `{DOCROOT}/lazysite/layouts/<LAYOUT>/themes/<THEME>/` →
   `theme.json`, `assets/`.
7. **Mirror** the `assets/` subtree to
   `{DOCROOT}/lazysite-assets/<LAYOUT>/<THEME>/`. This is the
   step that makes the CSS web-reachable; without it the layout
   loads a 404 stylesheet.

### 4.4 Activate

8. Set the active layout and theme (atomic), then clear/rebuild
   the page cache site-wide so cached pages re-render against the
   new chrome. (This matches the existing layout-activate
   semantics: activation rebuilds the mirror and busts the cache.)

### 4.5 Validation the processor should enforce

- Reject a theme whose `theme.json.layouts[]` does not contain the
  target layout (guards against installing a mismatched theme).
- Reject if `layout.json.name` != directory/manifest name.
- Treat the active layout/theme as **write-locked** (PUT to it is
  403 by the WebDAV contract). To update the active layout/theme,
  the processor must deactivate (switch to another), write, then
  reactivate — or perform the write as part of the activation
  transaction.

---

## 5. Decisions to settle before coding

### 5.1 Install all themes, or just one?

`themes[]` lets the processor offer either. Recommended default:
install `default_theme` only, and lazily fetch the others if the
user switches theme. For the 21 single-theme layouts this is moot
(one theme). Only `default` has five.

### 5.2 Distribution channel: raw files vs GitHub Releases

Two viable sources, pick one and make the processor consistent:

- **Raw files on a ref** — fetch `manifest.json` and the
  `releases/**/*.zip` blobs from a branch/tag via
  `raw.githubusercontent.com`. Works with what's committed today;
  no release step needed.
- **GitHub Release assets** — attach the zips + manifest to a
  tagged Release; processor reads the release. Cleaner versioning,
  but requires a publish step (tag + upload) that this repo's
  maintainer must run; Claude cannot push/tag on this host.

The manifest `package` paths above are repo-relative, which suits
the raw-files model. For the Release-asset model, the processor
would map each `package` basename to a release asset of the same
name.

### 5.3 Portable asset path vs hardcoded (important)

`default/layout.tt` uses the **portable** form:

```tt
[% IF theme_assets %]<link rel="stylesheet" href="[% theme_assets %]/main.css">[% END %]
```

`[% theme_assets %]` resolves to `/lazysite-assets/<LAYOUT>/<THEME>/`
for whatever theme is active — so the layout works with *any* of
its themes.

The 21 new layouts instead **hardcode** the theme name:

```tt
<link rel="stylesheet" href="/lazysite-assets/nova/nova/main.css">
```

This is fine while a layout has exactly one theme (name == layout
name), but it means:

- A second theme added to such a layout will **not** load its own
  CSS — the link still points at the original theme's mirror.
- The processor's mirror step must place assets at
  `/lazysite-assets/<LAYOUT>/<THEME>/` where `<THEME>` equals the
  layout name for these layouts, or the hardcoded link 404s.

Recommendation: if multi-theme layouts are ever wanted, migrate
these layouts to `[% theme_assets %]` (a one-line change each).
Until then, the processor can rely on the one-theme-per-layout
invariant for everything except `default`. **This choice affects
the install flow**, so settle it before 4.3/4.7 are coded.

### 5.4 Webfont dependency

Several layouts (`cadre`, `atelier`, `nova`, ...) pull Google
Fonts via a `<link>` in `layout.tt`. That is a layout-level
external dependency carried inside the layout zip — no packaging
change needed, but note it: offline/locked-down installs will
render with fallback fonts. If self-hosted fonts are wanted later,
they belong in the **theme** `assets/` (and would then ride the
existing asset-mirror path automatically).

---

## 6. Backward compatibility

- Existing theme-only installs keep working: `releases/<LAYOUT>/<THEME>.zip`
  is unchanged.
- Adding `themes[]` / `default_theme` to `layout.json` is additive;
  older processors that ignore unknown keys are unaffected.
- `manifest.json` is new and optional for the theme-only flow; only
  the new layout-download flow requires it.

---

## 7. Summary of concrete changes

This repo (packaging side):

1. New `releases/layouts/<LAYOUT>.zip` packages (layout.tt + layout.json).
2. `layout.json` gains `themes[]` and `default_theme`.
3. New root `manifest.json` enumerating layouts -> themes with versions + package paths.
4. `tools/` builds all three in one pass.

Processor side:

5. Read `manifest.json` to resolve a layout and its themes.
6. Download + install the layout package.
7. Download + install each associated theme; mirror `assets/` to `/lazysite-assets/<LAYOUT>/<THEME>/`.
8. Activate (atomic) + cache clear; honour the active-target write-lock.
9. Validate `theme.json.layouts[]` membership and name/dir agreement.
10. Decide the open questions in section 5 (esp. 5.3 hardcoded asset path) before implementation.
