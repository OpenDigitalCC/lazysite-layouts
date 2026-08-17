# lazysite-layouts

Layouts and themes for [lazysite](https://lazysite.io) under
the D013 architecture. Requires lazysite **0.2.10 or later** -
earlier versions use a different (incompatible) theme format.

## Current state of the catalogue (15 August 2026)

**Twenty-two of the twenty-three layouts are gallery demonstrations and are
not yet usable for a real site.** They render their own in-page anchors instead
of the site's navigation, and lack share cards, a canonical link, the
cache-safe auth indicator and a mobile navigation control. `default` is the
only complete one and is the reference for bringing the rest up.

- `docs/BRINGING-THE-CATALOGUE-UP-TO-DATE.md` - what each layout needs below
  `</head>`, in what order, and the one fixture that verifies all of it.
- `docs/proposals/2026-08-15-head-meta-contract.md` - the `<head>` half:
  `page_meta_title`, `page_meta_desc`, and the double-escaped description that
  ships today on any copy containing an apostrophe.

Read both before starting work on any layout in this repository.

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
      docs/
        creating-layouts.md
        creating-themes.md
      tools/
        package-themes.sh      <- rebuilds releases/*.zip from layouts/
      releases/
        default/              <- layout-scoped; mirrors source structure
          default.zip  dark.zip  studio.zip
          warm.zip     terminal.zip

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

Layouts are not currently shipped in release zips (themes are).
Copy manually:

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

The layout-scoped nesting means two layouts can each ship a
`default` theme (or any same-named theme) without collision.

## Rebuilding the packages

After editing a theme (or adding a new one), rebuild:

    tools/package-themes.sh

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
Currently this repo ships one layout; new layouts are rare
additions since themes are scoped per layout.

## Compatibility

- lazysite 0.2.10+ - required. Earlier lazysite versions use a
  pre-D013 theme format with `view.tt` and no `layouts[]`/
  `config{}` in `theme.json`. Themes from this repo won't install
  there.

## Licence

MIT.
