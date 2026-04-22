# Creating a layout for lazysite-layouts

A **layout** is the structural HTML template that wraps every
page. Under D013, the layout owns the HTML chrome (`<head>`,
site header, nav, main container, footer) and nothing else -
colours, fonts, and assets come from the **theme** layered on
top via CSS custom properties.

This repo currently ships one layout (`default`). This guide
walks through authoring a new one.

## What belongs in a layout

- `<head>` markup: meta tags, title, OG/canonical links.
- Top-level HTML structure: header, nav, main, footer.
- TT variable consumption: rendering `[% content %]`, iterating
  `[% FOREACH item IN nav %]`, emitting `[% theme_css %]`, etc.
- Semantic class names (`site-header`, `page-body`, etc.) that
  themes will style.

## What does NOT belong in a layout

- **Colour values.** Not even one. Every colour comes from
  theme tokens. If you find yourself writing `#fff` in the
  layout, stop - it belongs in `theme.json`.
- **Inline `<style>` blocks.** Beyond the single
  `[% theme_css %]` TT variable, the layout should have zero
  CSS. If you want shared structural styles, ship them in the
  theme's `main.css`.
- **Brand elements.** Logos, strap-lines, specific fonts. The
  layout stays brand-neutral.
- **nav.conf contents.** Nav is user content, parsed by the
  processor from `{DOCROOT}/lazysite/nav.conf`.

## layout.json

Sits next to `layout.tt`. Metadata only; not validated by the
core installer.

    {
      "name": "default",
      "version": "1.0.0",
      "description": "Default lazysite page layout with header, nav, main, footer",
      "author": "OpenDigitalCC"
    }

**Required:** `name` (must match directory), `version` (semver).
**Optional:** `description`, `author`.

## layout.tt - the TT contract

The processor passes these variables into `layout.tt`:

| Variable              | Type   | Notes                                              |
| --------------------- | ------ | -------------------------------------------------- |
| `content`             | HTML   | The rendered page body                             |
| `page_title`          | string | Front-matter `title`                               |
| `page_subtitle`       | string | Front-matter `subtitle`                            |
| `page_modified`       | string | Human-readable file mtime                          |
| `page_modified_iso`   | string | ISO 8601 file mtime                                |
| `page_source`         | string | Docroot-relative path of the source .md           |
| `request_uri`         | string | Current URL path, e.g. `/about`                    |
| `site_name`           | string | From lazysite.conf                                 |
| `site_url`            | string | From lazysite.conf                                 |
| `nav`                 | array  | Parsed nav.conf; each item has label, url, children |
| `layout_name`         | string | The active layout's directory name                 |
| `theme`               | hash   | Parsed theme.json; `theme.config.GROUP.KEY` access |
| `theme_name`          | string | Active theme (unset if incompatible)               |
| `theme_assets`        | string | `/lazysite-assets/LAYOUT/THEME/` (nested)          |
| `theme_css`           | HTML   | `<style>:root { --theme-*-*: ...; }</style>`       |
| `authenticated`       | bool   | True if the request carries valid auth headers     |
| `auth_user`, `auth_name`, `auth_groups` | varies | User identity         |
| `manager`, `manager_path`       | string | Manager UI settings                      |
| `year`                | string | 4-digit current year                               |

### Minimum layout.tt

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>[% page_title %][% IF site_name %] - [% site_name %][% END %]</title>
      [% theme_css %]
      [% IF theme_assets %]
      <link rel="stylesheet" href="[% theme_assets %]/main.css">
      [% END %]
    </head>
    <body>
      [% IF nav.size %]
      <nav class="site-nav">
        [% FOREACH item IN nav %]
          <a href="[% item.url %]">[% item.label %]</a>
        [% END %]
      </nav>
      [% END %]
      <main>
        <h1>[% page_title %]</h1>
        [% IF page_subtitle %]<p>[% page_subtitle %]</p>[% END %]
        [% content %]
      </main>
    </body>
    </html>

### Guarding theme references

When no compatible theme is active, `theme` is an empty hash,
`theme_name` is unset, and `theme_css` is an empty string. Guard
with `[% IF theme_assets %]` before emitting links:

    [% IF theme_assets %]
    <link rel="stylesheet" href="[% theme_assets %]/main.css">
    [% END %]

Without the guard, the `<link>` emits an empty `href` and
browsers follow the page URL as the stylesheet. Harmless but
produces a noisy 200 in the access log.

### How the layout coordinates with theme_css

The `theme_css` variable is a `<style>` block emitted into
`<head>` BEFORE your own `<link>` to `main.css`. The block
defines CSS custom properties at `:root`; your theme's CSS
references those properties via `var(--theme-GROUP-KEY)`.

The ordering matters: `theme_css` in `<head>` must come before
any rule that `var()`s its properties, so `main.css` reliably
sees them.

## How themes target a layout

Each theme declares its compatible layouts in `theme.json`:

    {
      "name": "odcc",
      "layouts": ["default"],
      ...
    }

lazysite's manager installs the theme under every layout named
in `layouts[]` (files duplicated under each). At render time
the processor validates that the active layout's name is in
the theme's `layouts[]` array; mismatches render layout-only
with no theme styling.

As a layout author: pick a stable name and version. Changing
the layout name without changing its semantics breaks every
theme that targets it. Prefer publishing a new layout name
over silently changing an existing one.

## The embedded fallback differs

lazysite ships an embedded fallback layout in the processor
itself. It renders when no layout is configured or the named
layout isn't installed. The fallback is a 98-line
survival-grade shell: viewport meta, basic typography, site
bar, nav, footer. It ignores `theme_css` (no `:root` tokens)
and is intentionally plain.

**Your layout should not look like the embedded fallback.**
The fallback exists so a half-broken site still renders; your
layout should do more - structured main, proper header, full
SEO/OG meta, nav with dropdowns, etc.

## Installing a layout

Layouts are not currently distributed via lazysite-layouts
release zips - only themes are. Operators install a layout
manually:

    mkdir -p /path/to/public_html/lazysite/layouts/default
    cp layouts/default/layout.tt   /path/to/public_html/lazysite/layouts/default/
    cp layouts/default/layout.json /path/to/public_html/lazysite/layouts/default/

Then in `lazysite.conf`:

    layout: default

This may change in a future release as the distribution
mechanism is extended, but at 0.3.x the manual copy is the
documented path.

## Compatibility

Target: lazysite 0.2.10 or later. The `[% theme_css %]` and
nested `theme_assets` URL shape were introduced by D013; earlier
lazysite versions don't expose them.

## See also

- [Creating a theme](creating-themes.md) - for authoring
  themes that target this layout
- Upstream lazysite docs: layouts.md, themes.md (shipped with
  the core repo)
