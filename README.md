# lazysite-layouts

Layouts and themes for [lazysite](https://lazysite.io) under
the D013 architecture. Requires lazysite **0.2.10 or later** -
earlier versions use a different (incompatible) theme format.

## What's here

    lazysite-layouts/
      layouts/
        default/
          layout.tt            <- structural HTML template
          layout.json          <- layout metadata
          themes/
            default/           <- light theme (ships in releases/default/default.zip)
              theme.json
              assets/main.css
            dark/              <- dark theme (ships in releases/default/dark.zip)
              theme.json
              assets/main.css
      docs/
        creating-layouts.md
        creating-themes.md
      tools/
        package-themes.sh      <- rebuilds releases/*.zip from layouts/
      releases/
        default/              <- layout-scoped; mirrors source structure
          default.zip
          dark.zip

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

| Theme   | Description                                      |
| ------- | ------------------------------------------------ |
| default | Clean neutral light theme, no external assets    |
| dark    | Dark theme, no external assets                   |

Both ship under the `default` layout. Theme `config` values
drive every meaningful colour in `main.css` via CSS custom
properties - edit `theme.json`, get a recoloured theme, no
CSS edits needed.

## Downloads

Pre-built zip packages mirror the source structure:
`releases/LAYOUT/THEME.zip`.

- [releases/default/default.zip](releases/default/default.zip) - light theme
- [releases/default/dark.zip](releases/default/dark.zip) - dark theme

The layout-scoped nesting means future layouts (e.g. `studio`)
can each ship a `default` theme without collision.

## Rebuilding the packages

After editing a theme (or adding a new one), rebuild:

    tools/package-themes.sh

The script walks `layouts/*/themes/*/` and produces one zip per
theme at `releases/LAYOUT/THEME.zip`. Each zip has the D013
upload shape: `theme.json` at root, `assets/` subtree for
web-served files.

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
