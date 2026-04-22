# Creating a theme for lazysite-layouts

A theme in the D013 architecture supplies colours, fonts, and
assets that layer on top of a **layout**. The layout owns the
HTML chrome (header, nav, main, footer); the theme supplies the
palette, the typography, and any images or fonts the design
needs. Content lives in the user's Markdown files - neither
layout nor theme touch it.

This guide walks through authoring a new theme for the default
layout shipped here.

## The three-layer model

    layout      - structural HTML template (layout.tt) + layout.json metadata.
                  Installed at {DOCROOT}/lazysite/layouts/NAME/.
                  lazysite-layouts currently ships ONE layout (default).
    theme       - design tokens + CSS + assets. Installed nested
                  at {DOCROOT}/lazysite/layouts/LAYOUT/themes/THEME/.
                  This repo ships two themes: default, dark.
    user        - .md pages, nav.conf, favicon. Unchanged by
                  theme or layout switches.

The processor reads `theme.json`, emits a `<style>:root { ... }`
block of CSS custom properties, and serves the theme's `assets/`
subtree at `/lazysite-assets/LAYOUT/THEME/`. The layout template
picks up both via the TT variables `theme_css` and `theme_assets`.

## theme.json

Required fields:

- `name` - matches the theme directory name. Sanitised to
  `[A-Za-z0-9_-]` on install.
- `version` - semver string.
- `description` - free-text.
- `author` - free-text.
- `layouts` - array of layout names this theme is compatible
  with. The manager rejects an upload whose `layouts[]` is
  missing or empty. The processor ignores a theme if the active
  layout isn't in this array.
- `config` - object grouping design tokens.

Optional:

- `files` - list of files that land in the zip. Informational
  only; the packaging script walks the theme directory rather
  than consulting this field.

### config and CSS custom properties

`config` is a two-level object: **group → key → value**. The
processor walks it and emits:

    <style>
    :root {
      --theme-GROUP-KEY: VALUE;
      ...
    }
    </style>

Group names and keys are author-chosen. Values must be strings.
The characters `; { } < >` are stripped from values before
emission to stop a malformed value escaping the declaration.

Common groups:

- `colours` - hex or named CSS colours
- `fonts` - font-family stacks
- `spacing` - px, rem, em values
- `icons` - glyph choices

Example (the light theme in this repo):

    "config": {
      "colours": {
        "primary": "#0056b3",
        "primary-hover": "#003d80",
        "text": "#1a1a1a",
        "text-muted": "#555555",
        "text-dim": "#777777",
        "heading": "#111111",
        "background": "#fafafa",
        "background-alt": "#f0f0f0",
        "background-accent": "#e8f0fe",
        "background-dropdown": "#ffffff",
        "border": "#e0e0e0"
      },
      "fonts": {
        "body": "system-ui, -apple-system, sans-serif",
        "code": "ui-monospace, Menlo, Consolas, monospace"
      }
    }

The processor emits `--theme-colours-primary: #0056b3;` etc.,
which `main.css` references via `var(--theme-colours-primary)`.

## main.css - using the custom properties

Your theme's `assets/main.css` should reference the CSS custom
properties for anything that a sibling theme could plausibly
want to change:

    body {
      color: var(--theme-colours-text);
      background: var(--theme-colours-background);
      font-family: var(--theme-fonts-body);
    }

    a {
      color: var(--theme-colours-primary);
    }

    a:hover {
      color: var(--theme-colours-primary-hover);
    }

Anything that is *not* a brand choice (spacing, layout geometry,
transitions) can stay hardcoded. Don't tokenise for the sake of
it - the value of the token system is that forking by copy and
editing `theme.json` changes the look without touching CSS.

### The keys-must-match rule

The `var(--theme-GROUP-KEY)` refs in `main.css` must match the
`config.GROUP.KEY` entries in `theme.json` one-to-one. A `var()`
with no corresponding config entry resolves to empty at runtime
and the property silently goes missing (or falls back to its
default, which may be "unset").

When you add a new token, add both:

1. `theme.json`: a new entry under the appropriate group.
2. `main.css`: a `var(--theme-GROUP-KEY)` reference where
   you want it applied.

## Fork-by-copy pattern

The recommended way to make a new theme is:

1. Copy an existing theme directory:

        cp -r layouts/default/themes/default layouts/default/themes/mytheme

2. Edit `theme.json`:
   - Change `name` to match the new directory.
   - Adjust `config` values to the new palette.

3. If your design needs additional CSS beyond what tokens
   cover, add it to `main.css`. The base CSS mostly "just
   works" across forks because it's driven by tokens.

4. Package and test:

        tools/package-themes.sh

That rebuilds `releases/default/mytheme.zip` (layout-nested)
alongside the others.

## Layout compatibility

The `layouts` array in `theme.json` declares which layouts
this theme is designed for. For themes in this repo, that's
usually `["default"]`.

If lazysite-layouts ever ships a second layout (say, `landing`),
a theme designed for both would declare `["default", "landing"]`
and would be installed under both at upload time (files
duplicated under each).

A theme declaring a layout that isn't installed on the target
site is rejected by the manager at upload. A theme installed
for a layout the operator isn't currently using is ignored at
render time (no warning, no error - just no styling from this
theme).

## Assets

The `assets/` subdirectory is served at
`/lazysite-assets/LAYOUT/THEME/` on the live site. Put any
file your CSS needs to reference there:

    layouts/default/themes/mytheme/
      theme.json
      assets/
        main.css
        logo.svg
        fonts/
          inter-regular.woff2

Reference them from `main.css` with relative paths:

    @font-face {
      font-family: Inter;
      src: url("fonts/inter-regular.woff2") format("woff2");
    }

...or from `layout.tt` via `[% theme_assets %]/logo.svg`, though
for lazysite-layouts themes the layout template is fixed and
doesn't know about per-theme assets - keep asset references in
`main.css`.

## Packaging

The `tools/package-themes.sh` script walks every theme directory
under `layouts/*/themes/*/` and produces one zip per theme at
`releases/LAYOUT/THEME.zip` (mirroring the source tree). Each
zip has:

    theme.json         (at zip root)
    assets/
      main.css
      ... (any other assets)

No `layout.tt`, no `nav.conf`, no top-level `main.css` (the
latter wouldn't be web-accessible - only `assets/*` is served).

Run before every release:

    tools/package-themes.sh

The script clears `releases/` first so stale zips from removed
themes don't linger.

## Testing locally

With a lazysite install (0.2.10+):

1. Install the default layout on the target site:

        mkdir -p /path/to/public_html/lazysite/layouts/default
        cp layouts/default/layout.tt /path/to/public_html/lazysite/layouts/default/
        cp layouts/default/layout.json /path/to/public_html/lazysite/layouts/default/

2. Upload your theme via the manager UI at
   `/manager/themes > Upload theme`, or use "Install from
   Releases" if `layouts_repo` in `lazysite.conf` points at
   your published copy of this repo.

3. In `lazysite.conf`:

        layout: default
        theme: mytheme

4. Browse the site. The live page should render through
   `layout.tt` with `theme_css` injecting your config values
   into `:root` and `main.css` applying them.

5. Iteration loop: edit `theme.json`, re-run
   `tools/package-themes.sh`, re-upload. The processor
   auto-clears the TT cache on theme activation, so you don't
   need to manually invalidate anything.

## Compatibility

Target: lazysite 0.2.10 or later. Earlier versions used the
pre-D013 theme format (no `layouts[]`, no `config{}`, `view.tt`
as a theme file). This repo's zips will not install on those.

## See also

- [Creating a layout](creating-layouts.md) - for authoring
  layout templates
- Upstream lazysite docs: themes.md, layouts.md,
  theme-json.md (shipped with the core repo)
