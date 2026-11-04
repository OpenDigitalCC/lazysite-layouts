# The pocket-ops layout

An app-style working surface for operatives on phone, tablet and PC: one header
with the apps and the sign-in, the current app's own pages as a second row, a
Menu button on a narrow screen, light and dark, and the slots a site needs to
install as an app and keep working with no connection. It came from the OOM Lab
(filings of 19 and 21 October 2026) and has been made generic: the brand is the
site's name, the apps are the site's `nav.conf`, and nothing in it belongs to
one site.

Themes: `lab` (the default; warm neutrals, deep teal, Inter) and `control` (an
operations-room look: square panels, a cyan signal line, Archivo with JetBrains
Mono figures). Each is light and dark; both follow the device unless the person
chooses.

## Installing

    install_layout pocket-ops        (MCP), or Appearance > Install from the catalogue
    activate_theme  lab              (or control)

Engine versions:

- 0.15.13 or later. The layout's `layout.json` and both themes' `theme.json`
  say so under `requires`, because the point of this layout is an installed app
  that opens offline (`app_offline_pages` and `app_update`, SM1197, 0.15.13).
  The template variables it uses arrived earlier (`page_url` 0.15.11; the
  `app_*` settings and the Odoo sign-in banner 0.15.10; `url_safe` 0.15.3;
  `theme_version` 0.13.13): on 0.15.11 and 0.15.12 the layout renders and the
  app installs, but the engine's worker keeps no page.

The theme and layout the site is serving are read-only on every engine surface:
install an update beside the current one (a new theme name) and switch.

## What a page gets

```datatable
columns: Slot | Where | What it is
widths: 4.4cm | 4cm | X
bold: 1
tone: medium
---
Brand | header | `[% site_name %]` linking home, with a theme-coloured mark. Add a logo in the theme, not here.
Apps | header | `[% nav %]`, top level. A parent with no address links to its first child. The current app has `aria-current`.
Pages of the current app | second row | The children of the current app, when it has more than one. They are also nested under each app in the Menu panel.
Menu button | header | `[data-po-menu-toggle]` with `aria-expanded` and `aria-controls="po-nav"`. Shown on a screen under 44rem when the script runs; without script the apps row scrolls sideways.
Colour-scheme switch | header | `[data-po-theme]`: Auto, Light, Dark. The choice is kept in the browser.
Sign-in area | header | `[% odoo_signin_banner %]` when the site signs in with Odoo (the engine's `data-ls-odoo-signin` and `data-ls-odoo-signout` controls, which `lazysite-odoo.js` fills); otherwise `[% auth_control %]`, which the auth-sync script reveals from the session cookie. Never both.
Skip link | top of body | `.po-skip`, to `#main`.
Page head | `<main>` | `page_title` and `page_subtitle`.
Banner | under the page head | `<div data-po-banner hidden>`: one line saying offline (and how old the shown data is), changes waiting, sending, refused (with "Try again"), the sign-out question, another person's waiting changes, or a new version ready (with "Reload"). The offline kit fills it; it is `role="status"`, or `role="alert"` when something was refused.
Signed-out notice | under the banner | `[data-po-show-out]`. It shows only on a page whose content is wrapped in `<div class="po-app">`, for a visitor who is not signed in; the wrapped content is then hidden. Mark a public page with `data-po-public`.
Last updated | end of `<main>` | `page_modified` in a `<time>`.
Footer | footer | The copyright line, RSS and Atom links (distinct titles), the Site manager link when the manager is enabled, the "This is a Lazysite" credit, and the app status.
App status | footer | `<details data-po-app-status hidden>`: a tick or a cross and a few words ("Installed app", "Can be installed" with the browser's Install button, "Works offline" with the steps for browsers without an install dialog, or "App needs https"). Words carry the state as well as the mark. It stays hidden on a site that has no manifest.
Head | `<head>` | Share cards, `page_url` for `og:url` and the canonical link, feed autodiscovery, the favicon, `viewport-fit=cover`, every theme-asset link with `?v=[% theme_version %]`. The layout adds no manifest link: the engine does, for pages inside the app's scope.
```

The signed-out notice has a one-line default text. A site that wants its own
wording edits `layout.tt` in its own copy of the layout.

## The kit, and why it is in each theme

The engine serves a theme's `assets/` from `/lazysite-assets/<layout>/<theme>/`
and serves nothing from a layout folder (`lib/Lazysite/Manager/Themes.pm`,
`_mirror_theme_assets`; the layout package is `layout.tt`, `layout.json` and
`components/` only). So the kit ships inside each theme's `assets/` and the
layout links it through `[% theme_assets %]`. That repeats the same four files in
`lab` and `control`. If the engine ever serves layout assets, or a packaging step
injects a shared kit (as the fonts and the favicon are), the copies can go.

```datatable
columns: File (in each theme's assets/) | What it does
widths: 5cm | X
bold: 1
tone: medium
---
`theme-early.js` | In `<head>`, without defer: sets `data-po-js` on `<html>` and applies a stored colour scheme before the first paint. A file, not an inline script, so the page needs no inline code under the site's script policy.
`pocket-ops.js` | After the header: the scheme switch, the Menu button, the signed-in state (`data-po-signed-in` on `<html>`), the Odoo helper's `read` and `write` timed, stacked-table labels. Exposes `window.PocketOps`.
`offline-kit.js` | Last in `<body>`: kept reads, the write guard, the opt-in queue, the banner, the install status, sign-out. Exposes `window.PocketOpsOffline`. It needs `pocket-ops.js` and the Odoo helper, and does nothing on a page without them.
`patterns.css` | The shared patterns, in the theme's short names, and the menu panel. Loaded after `main.css`.
`icons/` | `app-64.png`, `app-192.png`, `app-512.png`, `app-maskable.png`: a neutral mark a site can use for its `app_icon_*` settings while it has none of its own.
```

Renamed from the lab: `lab-*` classes are `po-*`, `data-lab-*` attributes are
`data-po-*`, `Lab` is `PocketOps`, `LabOffline` is `PocketOpsOffline`, the storage
keys are `pocket-ops.*` and the IndexedDB name is `pocket-ops-offline`. The lab's
per-app sheets and its `core-me` identity read are not part of the catalogue: who
is signed in comes from the Odoo helper (`LazysiteOdoo.who()`, a name only), or
from the session marker on a site without Odoo. Messages say "Not sent yet" and
"the server", not "Odoo".

### What the kit does, and what an app opts into

Every read through `PocketOps.read(binding, params)` keeps its answer on the
device with the time, keyed by the call and its parameters; answers over 512 KB
are not kept. With no connection the kept answer comes back, marked `r.kept`;
with none kept, an answer that says so. The choice between the plain call and
the kit's is made at call time, after the helper has loaded, so an app that
reads at once is kept too.

`PocketOps.write` needs a connection. With none it answers "This needs a
connection. Nothing was sent" at once; a connection lost mid-request answers that
it is not known whether the change was received. A submit button is dimmed while
offline unless it carries `data-po-queues`.

`PocketOpsOffline.send({ key, binding, params, label })` keeps a change and sends
it now, on reconnect, on return to the page and every 30 s while waiting. It is
opt-in per action and only for an operation that looks for the key before
acting, so a send that was cut off and made again makes nothing twice. A refusal
keeps the values and shows the server's reason; a 401 waits for the person to
sign in again. `waitingList(el, binding, describe)` draws the "Not sent yet" list
with Discard for refused changes.

### Data rules

These are the rules from the 19 October spec; the kit enforces them and an app
should not work round them.

- The data on the device belongs to the person signed in. Each queued change
  records who made it and is sent only while that person is signed in; another
  person's waiting changes are named in the banner and left alone. Kept answers
  are cleared on a 401, when a different person is signed in, and on sign-out.
- Signing out asks first when the person has changes not yet sent: the banner
  says how many, that signing out deletes them, and offers "Stay signed in" and
  "Delete and sign out". With none, the kept answers are cleared and the person
  is signed out.
- While anything on the device is not on the server, the banner says so on every
  page of the app.
- A page the worker keeps must be the same for every visitor. A person's own
  data comes from the endpoint when the page runs, never from the kept page.

## The worker: the engine's

The engine keeps pages for an installed app: `app_offline_pages` and `app_update`
shipped in lazysite 0.15.13 (SM1197; `docs/feature-requests/SM1197-an-installed-app-opens-offline.md`
and `starter/docs/app.md` in the engine repository). So this layout ships no
worker template and no build step. A site sets, in `lazysite.conf`:

    app_name: Acme Ops
    app_short_name: Ops
    app_scope: /
    app_start_url: /
    app_theme_colour: #ffffff
    app_background_colour: #faf6f0
    app_icon_64: /lazysite-assets/pocket-ops/lab/icons/app-64.png
    app_icon_192: /lazysite-assets/pocket-ops/lab/icons/app-192.png
    app_icon_512: /lazysite-assets/pocket-ops/lab/icons/app-512.png
    app_icon_maskable: /lazysite-assets/pocket-ops/lab/icons/app-maskable.png
    app_offline_pages: /, /stock/, /stock/list
    app_update: wait

`app_offline_pages` lists the pages that must open with no signal; each must be
inside the scope, a real Markdown page, and the same for every visitor (no
`auth`, no `odoo-identity:`). With `app_update: wait` a new version waits until
the page asks, and the banner's "Reload" calls the engine's
`lazysite-app-update` event's `detail.apply()`. With the default `now` the new
version takes over at once and the banner never shows. After turning the app on,
invalidate the page cache so pages carry the manifest link.

## Short names

Every colour, font and size is in `theme.json`; `main.css` maps it to short
names that pages and app sheets use. A theme of this layout defines all of them.
`patterns.css` uses only these, never a colour value.

```datatable
columns: Short name | lab | control | Used for
widths: 4.2cm | 2.6cm | 2.6cm | X
bold: 1
tone: medium
---
`--canvas`, `--surface`, `--sunken` | warm paper, white, sand | cool grey, white, grey | Page, panels, wells
`--ink`, `--muted`, `--line`, `--line-strong` | warm dark | near black | Text and rules
`--accent` and `-hover`, `-ink`, `-soft`, `-strong` | deep teal | deep cyan | The brand colour and its states
`--ok`, `--warn`, `--bad`, `--info` and `-soft` | | | Status meanings
`--data-1` to `--data-4`, `--star`, `--scrim` | | | Charts, ratings, the dialog backdrop
`--font`, `--mono` | Inter | Archivo, JetBrains Mono | Words, and figures and codes
`--radius-sm`, `--radius`, `--radius-lg` | 6, 10, 16px | 0, 2, 2px | Corners
`--control`, `--touch`, `--scan`, `--header`, `--page` | 44, 44, 56, 56px, 75rem | same, 80rem | Sizes
`--t-xs` to `--t-3xl`, `--s-1` to `--s-7` | the same in both | | Type and spacing scales
`--radius-pill` | 999px | 0 | Filter chips, state badges, progress bars
`--dot-radius` | 50% | 0 | The dot in a state badge, step numbers
`--avatar-radius` | 50% | 0 | Avatars
`--label-case`, `--label-track` | none, 0 | uppercase, .08em | Table headings, tile labels, small headings
`--button-case`, `--button-track` | none, 0 | uppercase, .06em | Link-buttons drawn by app sheets
`--figure-font` | `var(--font)` | `var(--mono)` | Totals, hours, tile values, time cells
`--signal` | `var(--accent)` | cyan | Live and "now" marks
`--panel-rule` | undefined | 2px accent | The top edge of a panel; used as `border-top: var(--panel-rule, 1px solid var(--line))` after the panel's own border. Leave it undefined to keep the plain edge; `none` removes the edge.
```

App sheets load after `main.css`, so a theme cannot restyle an app pattern by
overriding it: a theme changes the shape and lettering of a pattern through the
short names above. A further theme of this layout copies a theme, changes
`theme.json`, and sets every name.

### Classes

`.po-top`, `.po-nav`, `.po-subnav`, `.po-who`, `.po-page-head`, `.po-foot` are the
frame (PageFrame). The patterns, in `patterns.css` and `main.css`:

```datatable
columns: Class | Pattern
widths: 5cm | X
bold: 1
tone: light
---
`.po-note` (`.ok .warn .bad .info`), `.po-signed-out`, `.po-msg` | Notes
`.po-badge`, `.po-state` | StatusBadge
`.po-chips` | FilterChips (scrolls inside its own row)
`.po-table-wrap` and `.po-table` (`.po-stack` for cards on a phone) | DataTable
`.po-form`, `.po-row`, `.po-fieldset`, `.po-check`, `.po-filter` | FormField, ChoiceField
`.po-fields`, `.po-totals`, `.po-notes`, `.po-stars`, `.po-split` | RecordDetails
`.po-apps` | AppCards (the whole card is the link)
`.po-banner` (`-warning -info -danger`), `.po-waiting` | ConnectionBanner, the waiting list
`[data-ls-odoo-prompt]` | SignInDialog (the Odoo helper's markup)
`.lazysite-form`, `.form-status`, `.lsf-*`, `details` | The engine's forms and disclosures
```

An example page, to see every pattern drawn by the live theme (the lab's own
style guide page is not shipped; this is the shape of one):

    ---
    title: Style guide
    subtitle: Every element, drawn by the live theme.
    ---
    <div class="po-app" data-po-public>
    <div class="po-chips"><button aria-pressed="true">All <b>12</b></button><button>Open <b>7</b></button></div>
    <div class="po-table-wrap"><table class="po-table po-stack"><thead><tr><th>Item</th><th>State</th><th class="num">Qty</th></tr></thead>
    <tbody><tr><td>Widget</td><td><span class="po-state">Ready</span></td><td class="num">1,204</td></tr></tbody></table></div>
    <p class="po-note ok">Saved.</p>
    </div>

## Things that bit the lab

- A worker registers, and a browser offers to install, only over https or on
  localhost. On a plain-http LAN address nothing happens and nothing says why;
  the footer status says so. The engine's registration script now warns in the
  console. For testing, Chrome's `chrome://flags/#unsafely-treat-insecure-origin-as-secure`
  takes the origin; Firefox's `dom.securecontext.allowlist` takes the bare host
  only.
- A site whose `assets/` was copied from the starter before 0.15.10 has no
  `lazysite-app.js`.
- Desktop Firefox has no install dialog; the page works offline in a tab. Chrome
  may not offer the install until the page has been used for a moment.
- After an app-sheet or theme change the installed app's worker serves the old
  sheet once and the banner offers "Reload". That is the worker working as
  designed.

## What has been checked here

`t/site-contract.t` and `t/pwa-layout.t` render the layout and check its slots,
links, fonts, licences and declared requirements; `tools/check-no-cdn.sh` passes.
The two themes were drawn in headless Chromium at 390 and 1280 pixels for this
catalogue entry. The offline kit, in its genericised form, has not been run here
against a live Odoo site; the lab's own tests (Chromium and Firefox ESR 153, two
sites, six apps) were of the lab's original files.
