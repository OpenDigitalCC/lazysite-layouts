# lazysite-layouts

Layouts and themes for [lazysite](https://lazysite.io) under
the D013 architecture. Requires lazysite **0.2.10 or later** -
earlier versions use a different (incompatible) theme format.

## Current state of the catalogue (4 November 2026)

**Twenty-five layouts and fifty-four themes**, each layout and theme shipped as a zip
under `releases/` and listed in `manifest.json`.

- **The site contract.** All 25 layouts render a site: navigation from
  `[% nav %]`, a mobile control, share cards, `page_url` for the canonical and
  `og:url`, `url_safe` on every whole link target, `?v=[% theme_version %]` on
  theme-asset links, feed autodiscovery, the cache-safe auth control and the
  Odoo sign-in banner. `explorer` is the one demonstration layout and is
  exempt from the navigation rule. `t/site-contract.t` asserts it.
- **The engine requirement.** Every `layout.json` states `requires.lazysite`
  (0.15.11 for the contract; `pocket-ops` 0.15.13) and `manifest.json` carries
  it. The engine does not enforce the key yet; see `requires` below.
- **One shared sheet.** `assets/base.css` holds the nested navigation, `.form-*`,
  states and overflow rules. Every layout links it before `main.css`, and
  `tools/package-themes.sh` injects it into every theme zip, so git carries it
  once. A theme that commits its own `assets/base.css` wins.
- **Two working-surface layouts.** `pocket-ops` (installable, works offline;
  themes `lab`, `control`, `meadow`, `midnight`; `docs/layouts/pocket-ops.md`) and
  `intranet` (gate bar, breadcrumbs, sidebar navigation; theme `intranet`;
  `docs/layouts/intranet.md`). Page-supplied counters in the intranet bar and a
  locked-item navigation mark are not provided: the engine has no field for them.
- **The measurement rig.** `tools/render-catalogue.sh` renders every layout and
  theme against the design-kit specimen and the form in steps at 390 and 1280,
  light and dark, on the engine's dev server and headless Chromium. Today's
  figures, `docs/measurements/2026-11-04-after-wave2.md`, against the baseline
  of the same morning (`docs/measurements/2026-11-04-catalogue-baseline.md`):

| Measure | Baseline (49 themes) | After wave 2 (54 themes) |
|---|---|---|
| Scroll sideways on the specimen | 47 | 0 |
| Style `.form-*` classes in the theme sheet | 6 | 54 |
| Unstyled option signature | 5 | 0 |
| Every STATES.md group styled | 0 | 54 |
| Unstyled state groups, total | 603 | 0 |
| Favicon resolves as SVG | 49 | 54 |

  Still showing: the five `default`-layout themes open no menu at 390 in the
  rig's toggle test (0 of 8 links visible; the baseline had the same), and the
  four `pocket-ops` themes show 3 of 8 links on the desktop bar. Neither is
  confirmed as a fault; both are for the edge check.
- **Where the docs are.** `docs/WORK-PLAN-2026-11-04.md` (the waves and what each
  did), `docs/creating-layouts.md`, `docs/creating-themes.md`,
  `docs/BRINGING-THE-CATALOGUE-UP-TO-DATE.md` (the 15 August specification, now
  landed), `docs/layouts/`, `docs/measurements/`. Not yet done: verification on
  a live edge host and the gallery redeploy.

## What's here

    lazysite-layouts/
      layouts/
        default/
          layout.tt            <- structural HTML template
          layout.json          <- layout metadata
          themes/
            default/           <- clean neutral light theme
              theme.json
              assets/main.css
            dark/              <- dark theme
            studio/            <- Swiss grid, red accent, square corners
            warm/              <- parchment + sage, serif headings (token-only)
            terminal/          <- dark monospace, green accent
        ...                    <- 25 layouts in all, 54 themes
      assets/
        base.css               <- shared sheet, injected into every theme zip
        favicon.svg            <- default favicon, injected likewise
      fonts/                   <- self-hosted woff2 store with licences
      docs/
        creating-layouts.md
        creating-themes.md
        layouts/               <- pocket-ops, intranet
        measurements/          <- rig reports
        WORK-PLAN-2026-11-04.md
      t/                       <- prove t/
      tools/
        package-themes.sh      <- rebuilds releases/ themes, then layouts and manifest
        package-layouts.sh     <- layout zips and manifest.json
        render-catalogue.sh    <- the measurement rig
      manifest.json            <- the catalogue: layouts, themes, requires
      releases/
        layouts/               <- one zip per layout
        default/              <- theme zips, layout-scoped
          default.zip  dark.zip  studio.zip ...

## The three-layer model

Under D013, lazysite separates page rendering into three layers:

- **Layout** - HTML chrome. Owns `<head>`, header, nav, main,
  footer. Installed at `{DOCROOT}/lazysite/layouts/NAME/`.
  Brand-neutral: no colours or fonts baked in.
- **Theme** - CSS + assets + design tokens. Installed nested at
  `{DOCROOT}/lazysite/layouts/LAYOUT/themes/THEME/`. Declares
  layout compatibility in `theme.json`'s `layouts[]` array.
- **User content** - Markdown pages, `nav.conf`, favicon.
  Unchanged by theme or layout switches.

Layouts and themes are coupled at the contract level: a theme
references CSS custom properties emitted from its own
`theme.json.config`, and the layout emits those custom
properties at `:root` via the `[% theme_css %]` TT variable.

## Installing

### Layout (one-time, manual)

Layouts ship as zips at `releases/layouts/LAYOUT.zip`, listed in
`manifest.json` with their `requires`. To copy one by hand:

    mkdir -p /path/to/public_html/lazysite/layouts/default
    cp layouts/default/layout.tt   /path/to/public_html/lazysite/layouts/default/
    cp layouts/default/layout.json /path/to/public_html/lazysite/layouts/default/

Then in `lazysite.conf`:

    layout: default

### Theme (via manager UI)

With `layouts_repo` set to
`OpenDigitalCC/lazysite-layouts` in `lazysite.conf`, the
manager at `/manager/themes` offers "Install from Releases".
Pick a tag; themes in that release install under the active
layout.

### Theme (manual zip)

Download any `releases/*.zip` and upload it via
`/manager/themes > Upload theme`, or extract it manually:

    mkdir -p /path/to/public_html/lazysite/layouts/default/themes/default
    unzip releases/default/default.zip \
        -d /path/to/public_html/lazysite/layouts/default/themes/default/

    mkdir -p /path/to/public_html/lazysite-assets/default/default
    cp -r /path/to/public_html/lazysite/layouts/default/themes/default/assets/. \
          /path/to/public_html/lazysite-assets/default/default/

Then activate:

    theme: default

## Setting up nav.conf

`nav.conf` is site content, not theme content. The processor
reads it from `{DOCROOT}/lazysite/nav.conf`; themes and layouts
don't ship one. Create yours:

    # {DOCROOT}/lazysite/nav.conf
    Home | /
    About | /about
    Docs | /docs

See the upstream lazysite docs for the full format.

## Available themes

Each theme declares its compatible layout in `theme.json`'s
`layouts[]`. The first five share the `default` layout; the rest
each ship their own layout (one theme per layout).

### On the `default` layout

| Theme    | Description                                       |
| -------- | ------------------------------------------------- |
| default  | Clean neutral light theme, no external assets     |
| dark     | Dark theme, no external assets                    |
| studio   | Swiss international: grotesk, red accent, square   |
| warm     | Parchment + sage, serif headings (token-only)     |
| terminal | Dark technical monospace, signal-green accent     |

### Personal / bio

| Theme        | Layout       | Description                                       |
| ------------ | ------------ | ------------------------------------------------- |
| bio-modest   | bio-modest   | Understated calling card: quiet serif, lots of air |
| bio-balanced | bio-balanced | Tidy professional personal site, clean and confident |
| bio-bold     | bio-bold     | Loud personal site: big type, vivid gradient, photo-forward |

### Blog

| Theme  | Layout | Description                                              |
| ------ | ------ | ------------------------------------------------------- |
| ledger | ledger | Classic three-panel blog: plain white, system font, blue links |
| quill  | quill  | Side-menu blog with a centred serif reading column, warm paper |
| folio  | folio  | Essayist reading theme: large serif, single column      |

### Gallery / portfolio

| Theme   | Layout  | Description                                            |
| ------- | ------- | ----------------------------------------------------- |
| noir    | noir    | Dark mosaic gallery: gold accent, varied tile sizes   |
| atelier | atelier | Gallery theme                                         |
| cadre   | cadre   | Editorial portfolio: off-white, marquee + project grid |
| reel    | reel    | Cinematic reel / showcase theme                       |

### Statement (expressive, single-layout showpieces)

| Theme   | Layout  | Description                                                  |
| ------- | ------- | ----------------------------------------------------------- |
| lumen   | lumen   | Light editorial statement: warm paper, cobalt, Fraunces serif |
| nova    | nova    | Kinetic dark statement: animated aurora, glass panels, glow |
| press   | press   | Newsprint brutalist: cream stock, black rules, news-red, ticker |
| pulse   | pulse   | Generative interactive: canvas flow-field hero, dark glass UI |
| flux    | flux    | Scroll-driven cinema: native CSS scroll animations, zero JS |
| chroma  | chroma  | Visitor controls the palette: live mood switcher + randomiser |
| console | console | The site as a working terminal: CRT aesthetic, type to navigate |

### System dashboard

| Theme        | Layout       | Description                |
| ------------ | ------------ | ------------------------- |
| portal-light | portal-light | Light system dashboard    |
| portal-dark  | portal-dark  | Dark system dashboard     |

### Professional services

| Theme        | Layout       | Description                       |
| ------------ | ------------ | --------------------------------- |
| consultancy  | consultancy  | Business consultancy theme        |
| publicsector | publicsector | Public-sector advisory theme      |

### App working surface (installable, works offline)

| Theme   | Layout     | Description                                                       |
| ------- | ---------- | ----------------------------------------------------------------- |
| lab      | pocket-ops | Warm neutrals, deep teal, Inter; light and dark                   |
| control  | pocket-ops | Operations-room look: square panels, cyan signal, Archivo + Mono  |
| meadow   | pocket-ops | Light, from clarity's palette                                     |
| midnight | pocket-ops | Always dark, from dark's palette                                  |

`pocket-ops` is the layout for a site that installs as an app on phone, tablet
and PC and keeps working with no connection: apps and their pages from
`nav.conf` in one header, a Menu button on a narrow screen, a banner slot, a
signed-out notice and the Odoo sign-in banner. It ships slots only: the offline
kit is the engine's. It needs lazysite 0.15.13. Four themes: `lab`, `control`,
`meadow` (light) and `midnight` (dark). See `docs/layouts/pocket-ops.md`.

### Intranet

| Theme    | Layout   | Description                                                  |
| -------- | -------- | ------------------------------------------------------------ |
| intranet | intranet | Gate bar, breadcrumbs, sidebar navigation; Inter and JetBrains Mono |

See `docs/layouts/intranet.md`.

Theme `config` values drive every meaningful colour (and often
the fonts) in `main.css` via CSS custom properties - edit
`theme.json`, get a recoloured theme, no CSS edits needed.

## Downloads

Pre-built zip packages mirror the source structure:
`releases/LAYOUT/THEME.zip`.

On the `default` layout:

- [releases/default/default.zip](releases/default/default.zip) - light theme
- [releases/default/dark.zip](releases/default/dark.zip) - dark theme
- [releases/default/studio.zip](releases/default/studio.zip) - Swiss grid theme
- [releases/default/warm.zip](releases/default/warm.zip) - warm minimal theme
- [releases/default/terminal.zip](releases/default/terminal.zip) - monospace theme

One theme per layout:

- [releases/bio-modest/bio-modest.zip](releases/bio-modest/bio-modest.zip)
- [releases/bio-balanced/bio-balanced.zip](releases/bio-balanced/bio-balanced.zip)
- [releases/bio-bold/bio-bold.zip](releases/bio-bold/bio-bold.zip)
- [releases/ledger/ledger.zip](releases/ledger/ledger.zip) - classic three-panel blog
- [releases/quill/quill.zip](releases/quill/quill.zip) - side-menu serif blog
- [releases/folio/folio.zip](releases/folio/folio.zip) - essayist reading theme
- [releases/noir/noir.zip](releases/noir/noir.zip) - dark mosaic gallery
- [releases/atelier/atelier.zip](releases/atelier/atelier.zip) - gallery
- [releases/cadre/cadre.zip](releases/cadre/cadre.zip) - editorial portfolio
- [releases/reel/reel.zip](releases/reel/reel.zip) - cinematic showcase
- [releases/lumen/lumen.zip](releases/lumen/lumen.zip) - light editorial statement
- [releases/nova/nova.zip](releases/nova/nova.zip) - kinetic dark statement
- [releases/press/press.zip](releases/press/press.zip) - newsprint brutalist
- [releases/pulse/pulse.zip](releases/pulse/pulse.zip) - generative interactive
- [releases/flux/flux.zip](releases/flux/flux.zip) - scroll-driven cinema
- [releases/chroma/chroma.zip](releases/chroma/chroma.zip) - visitor-controlled palette
- [releases/console/console.zip](releases/console/console.zip) - terminal-style site
- [releases/portal-light/portal-light.zip](releases/portal-light/portal-light.zip) - light dashboard
- [releases/portal-dark/portal-dark.zip](releases/portal-dark/portal-dark.zip) - dark dashboard
- [releases/consultancy/consultancy.zip](releases/consultancy/consultancy.zip) - business consultancy
- [releases/publicsector/publicsector.zip](releases/publicsector/publicsector.zip) - public-sector advisory
- [releases/intranet/intranet.zip](releases/intranet/intranet.zip) - intranet
- [releases/pocket-ops/lab.zip](releases/pocket-ops/lab.zip), `control.zip`, `meadow.zip`, `midnight.zip` - the app working surface

Layout zips are at `releases/layouts/LAYOUT.zip`.

The layout-scoped nesting means two layouts can each ship a
`default` theme (or any same-named theme) without collision.

## Rebuilding the packages

After editing a theme (or adding a new one), rebuild:

    tools/package-themes.sh

It also runs `tools/package-layouts.sh` and regenerates `manifest.json`.
To re-measure, `bash tools/render-catalogue.sh --out FILE.md` (set `RIG_PORT`
and `RIG_CDP` if the defaults 8097 and 9333 are taken; it stops if they are).

The script walks `layouts/*/themes/*/` and produces one zip per
theme at `releases/LAYOUT/THEME.zip`. Each zip has the D013
upload shape: `theme.json` at root, `assets/` subtree for
web-served files.

## Declared token vocabulary + repo lint

Every `layouts/<L>/layout.json` carries a declarative `tokens`
block - the `--theme-GROUP-KEY` vocabulary its reference CSS
consumes, derived from the layout's default theme `main.css`
(see `docs/creating-layouts.md`). After changing a default
theme's CSS, regenerate:

    perl tools/gen-tokens.pl

and lint the repo (the declaration must match a fresh scan):

    prove t/

`prove t/` also runs `t/site-contract.t`, which renders every layout
against an engine-shaped stash and asserts it can carry a real site:
navigation from `[% nav %]`, a mobile control, share cards + canonical,
the resolved `page_meta_*` head values, the cache-safe auth control and
the last-updated stamp. See "The site contract" in
`docs/creating-layouts.md`.

## Fonts - standing no-CDN rule

**No CDN anywhere in lazysite themes.** Fonts must be freely
licensed (OFL/Apache), bundled with the theme, and served from
the site itself. Never link `fonts.googleapis.com` or any other
external host from a layout or theme.

How it works here:

- Font files (latin-subset woff2) live once in the repo-level
  [`fonts/`](fonts/README.md) store, each family with its
  verbatim `OFL.txt`.
- A layout declares what it needs in `layouts/<L>/fonts.list`
  (`Family Name:400,500i,700`); a theme can carry its own
  `fonts.list` to override.
- `tools/package-themes.sh` generates `assets/fonts.css` and
  copies the woff2 + licences into `assets/fonts/` of every
  theme zip at packaging time - git carries each font exactly
  once, every shipped theme is self-contained.
- `layout.tt` links `[% theme_assets %]/fonts.css` before
  `main.css`.
- `tools/check-no-cdn.sh` gates the packaging build: any
  external resource reference under `layouts/` (stylesheet,
  script, `url()`, `@import`, preconnect, known CDN hosts)
  fails the build. Plain hyperlinks such as the footer credit
  are fine.

## Contributing

### A new theme

See [docs/creating-themes.md](docs/creating-themes.md). Fork an
existing theme directory, adjust `theme.json` config values,
repackage.

### A new layout

See [docs/creating-layouts.md](docs/creating-layouts.md).
The repository ships 25 layouts; new layouts are rare additions
since themes are scoped per layout.

## `requires`

A layout states the engine it was written for:

```json
"requires": { "lazysite": "0.15.11" }
```

The value is the lowest lazysite release whose template variables and filters
the layout uses. The engine does not read or enforce it yet: a layout on an
older engine installs and then fails or degrades at render time (an unknown
filter is a template error). `tools/gen-manifest.pl` carries it into
`manifest.json` so a caller can compare it with the engine before offering the
layout, and `t/site-contract.t` checks it is present and at least `0.15.11`.

Set it to the highest release any variable in the layout needs:

| Variable or filter | Needs |
| --- | --- |
| `theme_version` (`?v=` on theme-asset links) | 0.13.13 |
| `url_safe` (on every whole-value link target) | 0.15.3 |
| `odoo_signin_banner` | 0.15.10 |
| `page_url` (canonical and `og:url`) | 0.15.11 |

## Compatibility

- Each layout names the lowest lazysite it needs in `layout.json`
  (`requires.lazysite`, 0.15.11 to 0.15.13); see above.
- lazysite 0.2.10+ - required. Earlier lazysite versions use a
  pre-D013 theme format with `view.tt` and no `layouts[]`/
  `config{}` in `theme.json`. Themes from this repo won't install
  there.

## Licence

MIT.
