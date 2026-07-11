# fonts/ - self-hosted web font store

Standing policy: **no CDN anywhere in lazysite themes**. Fonts must be
freely licensed (OFL/Apache), bundled with the theme, and served from
the site itself. `tools/check-no-cdn.sh` enforces this at packaging
time.

This directory is the single repo-level store of the woff2 files
(latin subset) that themes need. Fonts live here exactly once; they
are **not** duplicated per theme in git. At packaging time
`tools/package-themes.sh` copies the required families into each theme
zip's `assets/fonts/` and generates a matching `assets/fonts.css`,
driven by the layout's `fonts.list` (see below). On a live site the
theme's `assets/` subtree is mirrored to
`/lazysite-assets/LAYOUT/THEME/`, so the fonts are served first-party.

## Layout

    fonts/
      fonts.json                 <- machine-readable faces map
      <family-slug>/
        <slug>-<weight>[-<weight>][-italic].woff2
        OFL.txt                  <- that family's licence, verbatim

Most files are variable fonts covering a weight span (Google Fonts
serves one variable file per family/style); the filename records the
span, e.g. `inter/inter-400-800.woff2`. Static-only families (e.g.
Spectral) have one file per weight. `fonts.json` maps each
(family, style, weight) a theme may request to the file that serves
it - `tools/gen-fonts-css.pl` reads it to emit `@font-face` rules.

## Licences

Every family here is licensed under the SIL Open Font License 1.1.
Each family directory carries the family's own `OFL.txt` (with its
copyright line) as published in the upstream google/fonts repository.
The OFL requires the licence to accompany the font files: the
packaging step copies `OFL.txt` into `assets/fonts/` alongside the
woff2 files, so every shipped theme zip satisfies it.

| Family              | Copyright                                        |
| ------------------- | ------------------------------------------------ |
| Anton               | 2020 The Anton Project Authors                   |
| Bricolage Grotesque | 2022 The Bricolage Grotesque Project Authors     |
| Cormorant Garamond  | 2015 the Cormorant Project Authors               |
| Fraunces            | 2018 The Fraunces Project Authors                |
| Inter               | 2020 The Inter Project Authors                   |
| JetBrains Mono      | 2020 The JetBrains Mono Project Authors          |
| Jost                | 2020 The Jost Project Authors                    |
| Lora                | 2011 The Lora Project Authors                    |
| Newsreader          | 2020 The Newsreader Project Authors              |
| Plus Jakarta Sans   | 2020 The Plus Jakarta Sans Project Authors       |
| Public Sans         | 2015 The Public Sans Project Authors             |
| Sora                | 2019 The Sora Project Authors                    |
| Space Grotesk       | 2020 The Space Grotesk Project Authors           |
| Spectral            | 2017 The Spectral Project Authors                |
| Syne                | 2017 The Syne Project Authors                    |
| Unbounded           | 2022 The Unbounded Project Authors               |

## How a theme requests fonts

A layout declares its fonts in `layouts/<L>/fonts.list`, one family
per line:

    Sora:400,600,700
    Inter:400,500

Weights suffixed `i` are italic (`Spectral:400,400i,500,500i`). A
single theme can override/extend with its own
`layouts/<L>/themes/<T>/fonts.list` (theme-level wins outright when
present - used by `default/clarity`, since the other `default` themes
are token-only and ship no fonts).

`layout.tt` links the generated stylesheet before `main.css`:

    <link rel="stylesheet" href="[% theme_assets %]/fonts.css">

and `fonts.css` references the files relatively
(`url('fonts/<file>.woff2')`), so everything resolves under the
mirrored assets tree with no external requests.

## Adding a family

1. Download the latin-subset woff2(s) from a source that provides the
   OFL/Apache upstream (e.g. the google/fonts repo), verify the
   `wOF2` magic bytes, and place them in `fonts/<family-slug>/`.
2. Add the family's `OFL.txt` (verbatim, with its copyright line).
3. Add the faces to `fonts.json` (style + weight -> file).
4. Reference it from a `fonts.list` and rebuild
   (`tools/package-themes.sh`).

Never link a font CDN from a layout or theme - the packaging build
fails on any external http(s) reference.
