# Catalogue baseline, 2026-11-04

One row per layout and theme, measured by `tools/render-catalogue.sh` against the design-kit specimen and the form in steps. Re-run the same command for the after measurement.

```
tools/render-catalogue.sh --out docs/measurements/2026-11-04-catalogue-baseline.md
```

Engine: lazysite 0.16.2 (v0.16.2) (the dev server, `tools/lazysite-server.pl`, rendering the real processor).
Route: the engine's standalone dev server rendering the real processor, with every layout pinned per page by front matter (SM120) and the asset mirror pre-filled under lazysite-assets/. The dev server rendered every pinned layout and its mirror; the Template Toolkit fallback was not needed.

## Summary of counts

| Measure | Count |
|---|---|
| Themes measured (layouts) | 49 (23) |
| Scroll sideways on the specimen at 390 or 1280, either scheme | 47 of 49 |
| Scroll sideways on the form in steps | 0 of 49 |
| Scroll sideways on either page | 47 of 49 |
| Nested nav drawn as open lists (unstyled) | 0 of 49 |
| Nested nav a closed menu | 38 of 49 |
| Nested nav open but styled (bar or sidebar) | 10 of 49 |
| Nested nav partly visible | 0 of 49 |
| Mobile menu opened by its toggle shows every child | 43 of 49 |
| Mobile menu opened shows children as bullet lists | 0 of 49 |
| No nav rendered (demonstration layout) | 1 of 49 |
| Style `.form-option` or `.form-options` | 0 of 49 |
| Style any `.form-*` class (theme sheet) | 6 of 49 |
| Unstyled option signature (full-width, bordered option) | 5 of 49 |
| Favicon link resolves 200 as SVG | 49 of 49 |
| Themes with every STATES.md group styled | 0 of 49 |
| Unstyled state groups, total | 603 |

First culprit of the sideways scroll, by element: `a` (43), `h3` (2), `div.pub` (2).

## Per layout and theme

Scroll cells give the width and how far the document is wider than the window, in either scheme. The nav cell reads the rendered `[% nav %]` at 1280: closed menu, open and styled, or open and unstyled. The form cell is the `.form-option` / `.form-options` rule count in the theme sheet and the layout head. States is the number of the 15 STATES.md groups with no style in `assets/main.css`.

| Layout / theme | Specimen scroll | Steps scroll | First culprit | Nested nav | Form options | Favicon | States unstyled |
|---|---|---|---|---|---|---|---|
| atelier/atelier | 390 +711px; 1280 +78px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| atelier/atelier-noir | 390 +711px; 1280 +78px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-balanced/bio-balanced | 390 +783px; 1280 +177px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-balanced/bio-balanced-night | 390 +783px; 1280 +177px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-bold/bio-bold | 390 +783px; 1280 +177px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-bold/bio-bold-ultra | 390 +783px; 1280 +177px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-modest/bio-modest | 390 +791px; 1280 +201px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| bio-modest/bio-modest-slate | 390 +791px; 1280 +201px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| cadre/cadre | 390 +711px; 1280 +68px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| cadre/cadre-mono | 390 +711px; 1280 +68px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| chroma/chroma | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 12 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| chroma/chroma-dusk | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 12 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| console/console | no | no | - | open-styled: all 8 open, 63px tall, 13 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| console/console-amber | no | no | - | open-styled: all 8 open, 63px tall, 13 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| consultancy/consultancy | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 21 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| consultancy/consultancy-slate | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 21 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| default/clarity | 390 +775px; 1280 +128px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 10 |
| default/dark | 390 +709px; 1280 +143px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 0 of 8 visible | unstyled-signature: no rule; each option full-width with a border | 200 svg+xml | 6 |
| default/default | 390 +709px; 1280 +143px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 0 of 8 visible | unstyled-signature: no rule; each option full-width with a border | 200 svg+xml | 6 |
| default/studio | 390 +606px; 1280 +22px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 0 of 8 visible | unstyled-signature: no rule; each option full-width with a border | 200 svg+xml | 6 |
| default/terminal | 390 +936px; 1280 +373px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 0 of 8 visible | unstyled-signature: no rule; each option full-width with a border | 200 svg+xml | 6 |
| default/warm | 390 +709px; 1280 +163px | no | `a` | menu: closed by default, 6 rule(s); 390: toggle opens: 0 of 8 visible | unstyled-signature: no rule; each option full-width with a border | 200 svg+xml | 6 |
| explorer/explorer | 390 +1234px; 1280 +612px | no | `a` | none: no nav rendered; 390: none | unstyled: no .form-option rule | 200 svg+xml | 13 |
| flux/flux | 390 +752px; 1280 +85px | no | `a` | open-styled: all 8 open, 138px tall, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 14 |
| flux/flux-mono | 390 +752px; 1280 +85px | no | `a` | open-styled: all 8 open, 138px tall, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 14 |
| folio/folio | 390 +667px; 1280 +59px | no | `a` | menu: closed by default, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| folio/folio-dusk | 390 +667px; 1280 +59px | no | `a` | menu: closed by default, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| ledger/ledger | 390 +987px; 1280 +233px | no | `h3` | menu: closed by default, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 14 |
| ledger/ledger-sepia | 390 +987px; 1280 +233px | no | `h3` | menu: closed by default, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 14 |
| lumen/lumen | 390 +812px; 1280 +169px | no | `a` | menu: closed by default, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| lumen/lumen-rose | 390 +812px; 1280 +169px | no | `a` | menu: closed by default, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| noir/noir | 390 +711px; 1280 +60px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| noir/noir-steel | 390 +711px; 1280 +60px | no | `a` | menu: closed by default, 16 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| nova/nova | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| nova/nova-ember | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 17 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| portal-dark/portal-dark | 390 +685px; 1280 +58px | no | `a` | open-styled: all 8 open, 593px tall, 5 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| portal-dark/portal-dark-emerald | 390 +685px; 1280 +58px | no | `a` | open-styled: all 8 open, 593px tall, 5 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| portal-light/portal-light | 390 +685px; 1280 +58px | no | `a` | open-styled: all 8 open, 593px tall, 5 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| portal-light/portal-light-violet | 390 +685px; 1280 +58px | no | `a` | open-styled: all 8 open, 593px tall, 5 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| press/press | 390 +721px; 1280 +58px | no | `a` | menu: closed by default, 23 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| press/press-ink | 390 +721px; 1280 +58px | no | `a` | menu: closed by default, 23 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| publicsector/publicsector | 390 +717px; 1280 +40px | no | `a` | menu: closed by default, 21 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| publicsector/publicsector-green | 390 +717px; 1280 +40px | no | `a` | menu: closed by default, 21 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| pulse/pulse | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| pulse/pulse-magenta | 390 +731px; 1280 +54px | no | `a` | menu: closed by default, 18 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| quill/quill | 390 +819px; 1280 +353px | no | `div.pub` | open-styled: all 8 open, 708px tall, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| quill/quill-night | 390 +819px; 1280 +353px | no | `div.pub` | open-styled: all 8 open, 708px tall, 10 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| reel/reel | 390 +711px; 1280 +78px | no | `a` | menu: closed by default, 24 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |
| reel/reel-gold | 390 +711px; 1280 +78px | no | `a` | menu: closed by default, 24 rule(s); 390: toggle opens: 8 of 8 visible | unstyled: no .form-option rule | 200 svg+xml | 13 |

## States left unstyled

`lzs-design-kit.sh check <theme-folder>` on the pack as built. Run without a site, so the comparison with a site's kit tokens is skipped; everything else in the check runs. The check reads `assets/main.css` only, so a state the layout styles in its own head still counts as unstyled here.

| State group | Themes without a style |
|---|---|
| link hover | 2 of 49 |
| link keyboard focus | 43 of 49 |
| visited links | 49 of 49 |
| button hover | 43 of 49 |
| button keyboard focus | 49 of 49 |
| disabled button | 44 of 49 |
| field focus | 43 of 49 |
| invalid fields | 49 of 49 |
| placeholder text | 49 of 49 |
| checked boxes and radios | 49 of 49 |
| form messages | 43 of 49 |
| form success | 44 of 49 |
| form steps | 49 of 49 |
| disclosures | 44 of 49 |
| reduced motion | 3 of 49 |

Per theme, the groups with no style:

| Layout / theme | Groups unstyled |
|---|---|
| atelier/atelier | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| atelier/atelier-noir | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-balanced/bio-balanced | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-balanced/bio-balanced-night | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-bold/bio-bold | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-bold/bio-bold-ultra | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-modest/bio-modest | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| bio-modest/bio-modest-slate | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| cadre/cadre | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| cadre/cadre-mono | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| chroma/chroma | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| chroma/chroma-dusk | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| console/console | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| console/console-amber | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| consultancy/consultancy | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| consultancy/consultancy-slate | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| default/clarity | visited links, button keyboard focus, disabled button, invalid fields, placeholder text, checked boxes and radios, form success, form steps, disclosures, reduced motion |
| default/dark | visited links, button keyboard focus, invalid fields, placeholder text, checked boxes and radios, form steps |
| default/default | visited links, button keyboard focus, invalid fields, placeholder text, checked boxes and radios, form steps |
| default/studio | visited links, button keyboard focus, invalid fields, placeholder text, checked boxes and radios, form steps |
| default/terminal | visited links, button keyboard focus, invalid fields, placeholder text, checked boxes and radios, form steps |
| default/warm | visited links, button keyboard focus, invalid fields, placeholder text, checked boxes and radios, form steps |
| explorer/explorer | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| flux/flux | link hover, link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| flux/flux-mono | link hover, link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| folio/folio | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| folio/folio-dusk | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| ledger/ledger | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures, reduced motion |
| ledger/ledger-sepia | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures, reduced motion |
| lumen/lumen | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| lumen/lumen-rose | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| noir/noir | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| noir/noir-steel | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| nova/nova | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| nova/nova-ember | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| portal-dark/portal-dark | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| portal-dark/portal-dark-emerald | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| portal-light/portal-light | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| portal-light/portal-light-violet | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| press/press | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| press/press-ink | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| publicsector/publicsector | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| publicsector/publicsector-green | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| pulse/pulse | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| pulse/pulse-magenta | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| quill/quill | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| quill/quill-night | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| reel/reel | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |
| reel/reel-gold | link keyboard focus, visited links, button hover, button keyboard focus, disabled button, field focus, invalid fields, placeholder text, checked boxes and radios, form messages, form success, form steps, disclosures |

Other failures the check reports (counts of themes). The first three describe a design-kit return folder (notes and brand icons) rather than a catalogue pack:

| Failure | Themes |
|---|---|
| NOTES.md missing | 49 |
| theme.json has no dark scheme (config.dark); GUIDE.md asks for both | 49 |
| site/favicon.svg missing | 49 |
| site/apple-touch-icon.png missing | 49 |

## Nav and favicon proof, per layout (the 24/08 filing)

Each layout rendered a plain non-home page (`/contact`) on the rig with a nav of four top-level links, three groups and eight children. `Missing` lists labels or URLs not present as links. `Active` is the marker on the current page's item (top level on `/contact`, child on `/docs/authoring`). `Icon` is the declared `<link rel="icon">` href and what it returned. `No theme` pins a theme that does not exist.

| Layout | Missing | Active top / child | `#fragment` links | Icon | No theme |
|---|---|---|---|---|---|
| atelier | none | yes / yes | none | `/lazysite-assets/atelier/atelier/favicon.svg` 200 image/svg+xml | `/lazysite-assets/atelier/atelier/favicon.svg` 200 image/svg+xml |
| bio-balanced | none | yes / yes | none | `/lazysite-assets/bio-balanced/bio-balanced/favicon.svg` 200 image/svg+xml | `/lazysite-assets/bio-balanced/bio-balanced/favicon.svg` 200 image/svg+xml |
| bio-bold | none | yes / yes | none | `/lazysite-assets/bio-bold/bio-bold/favicon.svg` 200 image/svg+xml | `/lazysite-assets/bio-bold/bio-bold/favicon.svg` 200 image/svg+xml |
| bio-modest | none | yes / yes | none | `/lazysite-assets/bio-modest/bio-modest/favicon.svg` 200 image/svg+xml | `/lazysite-assets/bio-modest/bio-modest/favicon.svg` 200 image/svg+xml |
| cadre | none | yes / yes | none | `/lazysite-assets/cadre/cadre/favicon.svg` 200 image/svg+xml | `/lazysite-assets/cadre/cadre/favicon.svg` 200 image/svg+xml |
| chroma | none | yes / yes | none | `/lazysite-assets/chroma/chroma/favicon.svg` 200 image/svg+xml | `/lazysite-assets/chroma/chroma/favicon.svg` 200 image/svg+xml |
| console | none | yes / yes | none | `/lazysite-assets/console/console/favicon.svg` 200 image/svg+xml | `/lazysite-assets/console/console/favicon.svg` 200 image/svg+xml |
| consultancy | none | yes / yes | none | `/lazysite-assets/consultancy/consultancy/favicon.svg` 200 image/svg+xml | `/lazysite-assets/consultancy/consultancy/favicon.svg` 200 image/svg+xml |
| default | none | yes / yes | none | `/lazysite-assets/default/clarity/favicon.svg` 200 image/svg+xml | `/lazysite-assets/default/default/favicon.svg` 200 image/svg+xml |
| explorer | demonstration layout, no nav by design | no / no | #main | `/lazysite-assets/explorer/explorer/favicon.svg` 200 image/svg+xml | `/lazysite-assets/explorer/explorer/favicon.svg` 200 image/svg+xml |
| flux | none | yes / yes | none | `/lazysite-assets/flux/flux/favicon.svg` 200 image/svg+xml | `/lazysite-assets/flux/flux/favicon.svg` 200 image/svg+xml |
| folio | none | yes / yes | none | `/lazysite-assets/folio/folio/favicon.svg` 200 image/svg+xml | `/lazysite-assets/folio/folio/favicon.svg` 200 image/svg+xml |
| ledger | none | yes / yes | none | `/lazysite-assets/ledger/ledger/favicon.svg` 200 image/svg+xml | `/lazysite-assets/ledger/ledger/favicon.svg` 200 image/svg+xml |
| lumen | none | yes / yes | none | `/lazysite-assets/lumen/lumen/favicon.svg` 200 image/svg+xml | `/lazysite-assets/lumen/lumen/favicon.svg` 200 image/svg+xml |
| noir | none | yes / yes | none | `/lazysite-assets/noir/noir/favicon.svg` 200 image/svg+xml | `/lazysite-assets/noir/noir/favicon.svg` 200 image/svg+xml |
| nova | none | yes / yes | none | `/lazysite-assets/nova/nova/favicon.svg` 200 image/svg+xml | `/lazysite-assets/nova/nova/favicon.svg` 200 image/svg+xml |
| portal-dark | none | yes / yes | none | `/lazysite-assets/portal-dark/portal-dark/favicon.svg` 200 image/svg+xml | `/lazysite-assets/portal-dark/portal-dark/favicon.svg` 200 image/svg+xml |
| portal-light | none | yes / yes | none | `/lazysite-assets/portal-light/portal-light/favicon.svg` 200 image/svg+xml | `/lazysite-assets/portal-light/portal-light/favicon.svg` 200 image/svg+xml |
| press | none | yes / yes | none | `/lazysite-assets/press/press/favicon.svg` 200 image/svg+xml | `/lazysite-assets/press/press/favicon.svg` 200 image/svg+xml |
| publicsector | none | yes / yes | none | `/lazysite-assets/publicsector/publicsector/favicon.svg` 200 image/svg+xml | `/lazysite-assets/publicsector/publicsector/favicon.svg` 200 image/svg+xml |
| pulse | none | yes / yes | none | `/lazysite-assets/pulse/pulse/favicon.svg` 200 image/svg+xml | `/lazysite-assets/pulse/pulse/favicon.svg` 200 image/svg+xml |
| quill | none | yes / yes | none | `/lazysite-assets/quill/quill/favicon.svg` 200 image/svg+xml | `/lazysite-assets/quill/quill/favicon.svg` 200 image/svg+xml |
| reel | none | yes / yes | none | `/lazysite-assets/reel/reel/favicon.svg` 200 image/svg+xml | `/lazysite-assets/reel/reel/favicon.svg` 200 image/svg+xml |

22 of 22 site layouts (the demonstration layout, `explorer`, is exempt) render every configured label and URL on a non-home page.

A layout with no `default_theme` and no resolving theme (a copy of the `default` template with no `layout.json`): the icon link is `/favicon.svg`, which returned 404 text/html.

## What this run does not measure

- Hover, focus, visited, disabled, invalid and checked states are counted from the stylesheet text by the check, never exercised in a browser.
- No layout in the catalogue carries a `data-theme` switcher, so dark is measured by device-scheme emulation, with `data-theme="dark"` also set on `<html>` for the scroll measure.
- The nested nav is judged at 1280 and 390 on the rendered links only; a menu opened by hover or by the mobile toggle is not opened.
- The kit-token comparison in `check` needs a site's published kit and is skipped.
- The specimen's oEmbed block and QR code are static markup here; scripts the layouts load run as in a browser.

