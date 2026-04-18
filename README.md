# lazysite-views

A collection of views for [lazysite](https://lazysite.io) -
the Markdown-driven static site processor for Apache.

A **view** is a Template Toolkit file (`view.tt`) that controls
the visual presentation of every page on your lazysite site.
lazysite includes a built-in fallback view, so a custom view
is optional - install one when you want a specific design.

## Documentation

- [Creating views](docs/creating-views.md) - complete view creation manual

## Installing a view

### Option 1 - copy a single view file

Download `view.tt` from the view directory and place it at:

    public_html/lazysite/templates/view.tt

Example using curl:

    curl -o public_html/lazysite/templates/view.tt \
      https://raw.githubusercontent.com/OpenDigitalCC/lazysite-views/main/default/view.tt

### Option 2 - clone the repo and copy

    git clone https://github.com/OpenDigitalCC/lazysite-views.git
    cp lazysite-views/default/view.tt public_html/lazysite/templates/

### Option 3 - use as a theme (per-page switching)

Place the view in the themes directory:

    public_html/lazysite/themes/default/view.tt

Then set in `lazysite/lazysite.conf`:

    theme: default

Or per-page in front matter:

    layout: default

## Available themes

| Theme | Description |
| ----- | ----------- |
| default | Clean neutral light theme, no external dependencies |
| dark | Dark theme, no external dependencies |

## Downloads

Pre-built zip packages are in the `releases/` directory:

- [default.zip](releases/default.zip) — light theme
- [dark.zip](releases/dark.zip) — dark theme

Install manually:

    curl -sL https://github.com/OpenDigitalCC/lazysite-views/raw/main/releases/default.zip \
        -o /tmp/default.zip
    mkdir -p public_html/lazysite/themes/default
    unzip /tmp/default.zip -d public_html/lazysite/themes/default/
    mkdir -p public_html/lazysite-assets/default
    cp -r public_html/lazysite/themes/default/assets/* public_html/lazysite-assets/default/

Or upload via the lazysite editor: Editor > Themes > Upload theme.

Rebuild packages after updating themes:

    bash tools/package-themes.sh

## nav.conf

Each view directory includes a `nav.conf` example. Copy it to
`public_html/lazysite/nav.conf` and edit to match your site structure.

## Creating your own view

See [docs/creating-views.md](docs/creating-views.md) for the complete
view creation manual - variables, navigation pattern, CSS classes, TT
syntax, and a full working example.
