---
title: "Bringing the catalogue up to date"
subtitle: "Twenty-two of the twenty-three layouts are gallery demonstrations wearing the same manifest as a site layout. What each one needs before it can be offered for a real site"
brand: plain
standard-margins: true
---

# Status

A work specification, written 15 August 2026 after a site was built on this
catalogue and the layouts could not carry it. Nothing here is started.

The `<head>` half of the problem is already specified in
`docs/proposals/2026-08-15-head-meta-contract.md` and is **excluded** from this
document to avoid two descriptions of one change. That proposal covers
`page_meta_title`, `page_meta_desc` and the double-escaped description. This one
covers everything below `</head>`.

# What was measured

Every layout in `layouts/`, on 15 August 2026.

```datatable
columns: Capability | Layouts that have it
widths: 9.4cm | X
bold: 1
tone: medium
---
Renders `[% content %]` | 23 of 23
Renders the site's navigation from `[% nav %]` | 1 of 23
Mobile navigation control | 1 of 23
Share cards (`og:`, `twitter:`) | 1 of 23
Canonical link | 1 of 23
Cache-safe sign in / sign out indicator | 1 of 23
Last-updated stamp | 1 of 23
```

The one in every row is `default`. The other twenty-two have none of it.

**They do render page content.** That is worth stating plainly, because a first
reading of a gallery layout suggests otherwise: the demo chrome is substantial
and the page body arrives below it. `[% content %]` is present in all
twenty-three.

What they render instead of navigation is their own:

```datatable
columns: Layout | Links it renders
widths: 4.2cm | X
bold: 1
tone: light
---
atelier | `#top`, `#works`, `#about`
consultancy | `#top`, `#services`, `#approach`, `#contact`, plus "Meridian & Co"
lumen | `#features`, `#voices`, `#essay`
press | `#stories`, `#column`, `#opinion`
nova | `#features`, `#showcase`, `#start`
```

These are in-page anchors to sections of a demonstration page. On a real site
they point at nothing, and `consultancy` prints a fictional company name in the
masthead of whatever site activates it.

# Why this is worth doing rather than documenting

The designs are the valuable part and they are unaffected. What is wrong is the
chrome around them, which was written to showcase a design on a single
demonstration page and then shipped as though it were a site layout.

The catalogue gives no signal which is which. `list_layout_catalogue` returns
name, version, themes and tags, and the only way to discover that a layout
cannot carry a site is to install it, bind it to a domain, render a page and
look at the result. A partner agent asked to build a site with working
navigation currently cannot select one from this catalogue at all, and finds
out only after committing.

Every signal along the way reports success: `install_layout` returns `ok:1`,
`activate_layout` returns `ok:1`, `nav-save` returns `ok:1` and reports the
cache entries it cleared, `nav-read` returns the saved items against the right
`nav_file`, and the page returns 200. The navigation is simply absent.

# The reference

`layouts/default/layout.tt` is current, correct and complete. It is the model
for everything below, and it is short enough to read in one sitting.

It is also evidence that the contract was understood when it was written. Its
`<head>` comment states which variables arrive engine-escaped and why the
`meta_*` overrides get a filter and the others do not. The gallery layouts were
written without that knowledge, which is the root of both this document and the
head-meta proposal.

# What each layout must gain

## 1. The site's navigation

Replace the hard-coded links with `[% nav %]`. `default` has the full
treatment, and it is worth copying rather than paraphrasing:

- one level of children, rendered as a nested list;
- `class="active"` when `request_uri` matches the item's URL;
- a group label for a parent with children and no URL of its own.

Each design will want its own presentation of that structure. The structure
itself should not vary.

## 2. A navigation control that works on a phone

`default` ships a `.nav-toggle` button, hidden above 720px, with
`aria-expanded` and `aria-controls`, toggling a body class from eight lines of
inline script. Layouts whose navigation already collapses gracefully may not
need it; layouts with a horizontal bar of five or more items will.

The requirement is that every navigation item is reachable at 390px wide. That
is the assertion, rather than any particular mechanism.

## 3. Share cards and a canonical link

`og:title`, `og:description`, `og:type`, `og:site_name`, `og:url`,
`twitter:card`, `twitter:title`, `twitter:description`, and
`<link rel="canonical">`.

Take these from `default` verbatim once the head-meta proposal has landed there,
since both draw on the same resolved values and specifying them twice is how
they drift. Note `default`'s reasoning that `og:site_name` carries the site
name so `og:title` is the page title alone, without a redundant suffix.

## 4. The sign in / sign out indicator

Pages are cached and shared between visitors, so a server-side authentication
check bakes one visitor's state into everyone's HTML. `default` ships both
links hidden and lets the injected auth-sync script reveal the correct one from
the `lzs_session` cookie.

A layout that omits this is not merely missing a feature. A layout that
implements it the obvious way is serving the wrong state from cache, so the
pattern matters more than it appears.

## 5. The last-updated stamp

`page_modified` and `page_modified_iso` in a `<time>` element. Small, and it is
the kind of thing a layout is expected to offer.

# Two ways to finish, and a recommendation

Bring all twenty-two up to the contract
: the designs survive, the catalogue becomes uniformly usable, and
  `list_layout_catalogue` needs no new field. Cost is real but bounded: the
  changes are structural rather than creative, and `default` supplies the
  pattern for every one of them.

Or mark them as demonstrations and keep them as they are
: add a `kind` to `layout.json`, surface it in the manifest and the catalogue
  tool, and let a caller filter. Cheaper, and it leaves a catalogue of
  twenty-three offering one usable layout, which makes the theme work look like
  a gallery rather than a product.

**The first.** The designs are why this repository exists, and the work needed
is mechanical. The second option is worth taking as well, for whatever remains
genuinely demonstration-only after the sweep, and for the `explorer` layout,
which is the gallery's own index page and should probably say so.

# How to verify, once and for all layouts

A single fixture answers every question in this document, and it should land
with the first layout rather than the last.

For each layout: a two-item `nav.conf` with one child, a page with a known
title, a subtitle containing an apostrophe and an ampersand, and a body
containing a unique string. Render, then assert:

```datatable
columns: Assertion | Fails today on
widths: 8.6cm | X
bold: 1
tone: medium
---
Both nav labels and their URLs appear | 22 layouts
The child item appears | 22 layouts
The body's unique string appears | none
The subtitle decodes back to the input | 22 layouts
`<title>` reflects `page_meta_title` | 23 layouts
The description reflects `page_meta_desc` | 23 layouts
A canonical link is present | 22 layouts
```

The last three are the head-meta proposal's to satisfy; they are listed so one
fixture covers both pieces of work rather than each growing its own.

Walk the tree rather than globbing a level of it. Upstream `t/lint/46` exists
because `starter/docs/*.md` missed `starter/docs/integrations/`, and the miss
reached production.

# Suggested order

1. The fixture and the lint, failing, against the current tree. It is the only
   way to know the sweep is finished, and it makes each subsequent layout a
   small green step rather than a judgement call.
2. `default` re-verified against it, since it should pass everything except the
   head-meta items and is the control for the fixture itself.
3. One representative gallery layout end to end - `consultancy` is a good
   choice, being the furthest from correct and the closest to something a real
   business would pick. It establishes the per-layout cost.
4. The remaining twenty.
5. `explorer` last, and consider marking it a demonstration rather than fixing
   it.

# Where this came from

A mock customer site built on `edge2.explore.lazysite.io` during 0.10.9 field
testing. The brief asked for working navigation; three layouts were tried and
none could provide it, so a layout was authored instead. That layout is at
`lazysite-sites/edge.explore/mock-engagement/layout/kestrel/` and is about
thirty lines of Template Toolkit, which is a fair estimate of the distance
between a gallery layout and a working one.

The upstream filing is
`lazysite/inbox/no-installed-layout-renders-the-site-navigation-2026-08-15.md`.
