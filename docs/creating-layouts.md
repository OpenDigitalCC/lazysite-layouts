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
      "author": "OpenDigitalCC",
      "default_theme": "default"
    }

**Required:** `name` (must match directory), `version` (semver).
**Optional:** `description`, `author`, `default_theme` (the theme installed and
activated when a user installs the layout from the catalogue without choosing one;
also seeds `manifest.json`), `themes` (informational forward index - the manifest
itself is derived from the actual theme dirs, so this never has to be hand-kept).

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
| `sections`            | array  | D035 front-matter `sections:` (data-driven pages); empty `[]` unless declared |

A `markdown` filter is also available: `[% some_value | markdown %]` renders a
value that contains Markdown (single-paragraph values render inline). See
"Content components" below.

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

**Preview / per-page-layout gotcha.** When a layout is *previewed*
(or set per-page with `layout:`) and no theme is active for it,
`theme_assets` is empty, so the guard above emits **no stylesheet**
and the page renders unstyled. If your layout should still look right
in that state, give the link a fallback to a theme mirror you ship,
e.g.:

    [% IF theme_assets %]
    <link rel="stylesheet" href="[% theme_assets %]/main.css">
    [% ELSE %]
    <link rel="stylesheet" href="/lazysite-assets/LAYOUT/DEFAULT_THEME/main.css">
    [% END %]

(substitute your layout + its `default_theme`). A processor-side fix -
falling `theme_assets` back to the layout's `default_theme` mirror when
nothing is active - is on the lazysite backlog; until then this layout-side
fallback is the robust pattern.

### How the layout coordinates with theme_css

The `theme_css` variable is a `<style>` block emitted into
`<head>` BEFORE your own `<link>` to `main.css`. The block
defines CSS custom properties at `:root`; your theme's CSS
references those properties via `var(--theme-GROUP-KEY)`.

The ordering matters: `theme_css` in `<head>` must come before
any rule that `var()`s its properties, so `main.css` reliably
sees them.

## Content components (D035)

A layout may own reusable partials under `layouts/<layout>/components/<name>.tt`,
so authors write Markdown and the layout supplies the HTML. They are packaged into
the layout zip automatically (`package-layouts.sh`) and travel with the layout.

There are two ways an author invokes a component:

**Fenced** - a `::: <name>` block whose name matches a component:

    ::: hero eyebrow="Generative"
    # A site that's *alive*.

    ::: actions
    [Get started](#start)
    :::
    :::

The component receives `content` (the inner Markdown, rendered), `attrs` (the
`key="value"` pairs on the opening line), and `slots` (each nested `::: <slot>`
fence, rendered). `components/hero.tt`:

    <section class="hero">
      [% IF attrs.eyebrow %]<span class="eyebrow">[% attrs.eyebrow %]</span>[% END %]
      [% content %]
      [% IF slots.actions %]<div class="cta">[% slots.actions %]</div>[% END %]
    </section>

A fence whose name has no matching component still becomes a plain
`<div class="name">` (unchanged), so existing pages are unaffected.

**Front-matter `sections:`** - data-driven whole pages. The page lists sections;
the layout dispatches each to its component as `data`:

    ---
    sections:
      - hero:
          heading: "A site that's *alive*."
          actions:
            - { label: Get started, href: '#start', style: primary }
      - feature-grid:
          items:
            - { title: No framework, body: "Native CSS." }
    ---

    [%# in layout.tt %]
    [% FOREACH s IN sections %][% type = s.keys.first %]
    [% INCLUDE "components/${type}.tt" data = s.$type %][% END %]

Use `[% data.heading | markdown %]` for Markdown fields. **Dispatch must use
`${type}.tt`** (braces) - bare `$type.tt` is read by Template Toolkit as the
dotted variable `type.tt` and the INCLUDE fails.

`sections:` accepts both indented block style and inline flow style
(`items: [{title: A}, {title: B}]`, `tags: [a, b]`) - mix freely. (Flow style had
a parser bug through lazysite 0.4.68 that mis-counted list items; fixed after.)

Keep colours in CSS tokens (`--theme-colours-*`), never in the component HTML.
A component may `[% INCLUDE 'components/other.tt' %]` (the layout dir is on
`INCLUDE_PATH`). `EVAL_PERL` is off; authors never write Template Toolkit.

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
