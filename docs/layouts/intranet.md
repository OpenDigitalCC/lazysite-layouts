# The intranet layout

A working surface for a private section, not a shop window: dense, quiet, and
built around what a private section contains, which is tables, forms,
checklists and file lists. A dark bar across the top says which side of the
gate you are on, so nothing else has to. It came from the filings of 25 August
and 9 September 2026, which found three private surfaces on lazysite that each
invented their own class system; this layout is the one vocabulary they should
have shared.

Theme: `intranet` (the default), light and dark. Fonts are Inter and JetBrains
Mono, bundled; monospace is for identifiers and quantities, where a
proportional font makes two codes that differ by one character look alike.

## Installing

    install_layout intranet          (MCP), or Appearance > Install from the catalogue

The layout is meant to be served from its own domain record, an intranet
subdomain, whose record carries this layout, its theme and the group gate. A
page can choose its layout but a domain chooses the theme, so a private section
that shares a host with a public site would be served the public theme.

Engine versions: 0.15.11 or later (`page_url`). The sign-in banner for Odoo
sites, `url_safe` and `theme_version` arrived earlier.

## The shell

What `layout.tt` provides on every page. Authors write none of it.

```datatable
columns: Part | Class | What it does
widths: 3.4cm | 3.4cm | X
bold: 1
tone: medium
---
Gate bar | `in-bar` | Full width, dark in both schemes, with the site name at the left and the sign-in at the right: the Odoo banner when the site has one, otherwise the cache-safe sign-in and sign-out links.
Breadcrumbs | `in-crumbs` | Built from the request path, so every page has them. A segment that is an address in the nav takes the nav label; any other is the segment with its dashes read as spaces. The last is the page title.
Section nav | `in-side` | A sidebar from the site's nav: groups with their pages beneath, the current page marked. A parent with no address of its own is a group label. On a narrow screen it opens from the Menu button; without scripts it is listed above the page.
Page head | `in-head` | The title and the subtitle.
Column | `in-wrap`, `in-main` | One wide column, `min(1400px, 100vw - 2rem)`, shared by the bar, breadcrumbs, page and footer. Prose is capped at 62rem inside it; tables, panels and forms use the full width.
Footer | `in-foot` | The site name, the last-updated time, the feeds, the site manager link where enabled.
```

A page can ask for a different width with a custom front-matter key:

    ---
    title: Intake form
    width: narrow
    ---

`narrow` keeps the whole column to a reading measure (a form-heavy page);
`full` removes the cap (a long list). The key reaches the layout as
`page_width`. Anything else gives the default.

## The vocabulary

Author-facing classes, all prefixed `in-`. Keep to these; a second theme for
this layout is a token file and nothing else, so a treatment that needs a new
class means the vocabulary was wrong.

```datatable
columns: Class | For
widths: 4cm | X
bold: 1
tone: medium
---
`in-panel` | A bordered surface for one unit of content. A heading first inside it sits flush.
`in-cards` | A grid of panels that wraps from several columns to one.
`in-callout` | The "why you are looking at this record" note: a warm rule on a warm tint. Not a blockquote; nobody said it.
`in-chip` | A status mark, uppercase, with the word in it so colour is never the only signal.
`in-is-active`, `in-is-attention`, `in-is-settled`, `in-is-current` | The row and mark states, one set for chips, table rows, list items and checklist items (see below).
`in-num` | A table cell for a quantity: right-aligned, tabular figures, no wrapping.
`in-tight` | A table column that takes only the room it needs.
`in-sticky` | On a table: a long list keeps its header row in view.
`in-files` | On a table: a file list, with the name column in monospace and the size column on the right.
`in-checklist` | On a list: a box before each item, a tick and a strike on the settled ones.
`in-actions` | An action bar, right-aligned with a hairline above; a `in-button-danger` in it is pushed to the far left.
`in-button` | A quiet outline button on a link or a `div`; a `button` element already has it.
`in-button-primary`, `in-button-danger` | The one primary action, and the destructive one (warm, never in the run of ordinary choices).
`in-empty` | An empty state: a sentence a person would say, never "0 records".
```

The four states read as:

```datatable
columns: State | Reads as
widths: 4cm | X
bold: 1
tone: medium
---
neutral | No class. A grey chip: not started, nothing to say.
`in-is-active` | Accent on a pale tint: yours, current, selected.
`in-is-attention` | Warm: held by somebody else, over-allocated, a problem.
`in-is-settled` | Green: answered, complete, matched.
`in-is-current` | A 3px accent bar on the first cell of a row, or at the left of a checklist item: the one being looked at.
```

### Markup

A status in a table, with the row marked:

    <table>
      <thead><tr><th>Task</th><th class="in-tight">Owner</th><th class="in-tight">State</th><th class="in-num">Hours</th></tr></thead>
      <tbody>
        <tr class="in-is-current"><td>Reconcile March</td><td>Asha</td><td><span class="in-chip in-is-active">In hand</span></td><td class="in-num">6.5</td></tr>
        <tr class="in-is-attention"><td>Supplier queries</td><td>Dev</td><td><span class="in-chip in-is-attention">Held</span></td><td class="in-num">12</td></tr>
      </tbody>
    </table>

A checklist:

    <ul class="in-checklist">
      <li class="in-is-settled">Counts agree with the ledger</li>
      <li class="in-is-current">Exceptions explained</li>
      <li>Signed off</li>
    </ul>

A file list:

    <table class="in-files">
      <thead><tr><th>File</th><th>Size</th></tr></thead>
      <tbody><tr><td><a href="/files/march.csv">march.csv</a></td><td>41 KB</td></tr></tbody>
    </table>

A callout, a panel in cards, an action bar:

    <p class="in-callout">This record is open because two counts disagree.</p>

    <div class="in-cards">
      <section class="in-panel"><h3>Open</h3><p>14 tasks</p></section>
      <section class="in-panel"><h3>Held</h3><p>3 tasks</p></section>
    </div>

    <div class="in-actions">
      <a class="in-button in-button-danger" href="/withdraw">Withdraw</a>
      <a class="in-button" href="/cancel">Cancel</a>
      <button class="in-button-primary" type="submit">Save</button>
    </div>

## What needs no class

Authors write Markdown, so the layout styles the plain constructs and the class
is only for what Markdown cannot say.

- Tables: dense rows, a quiet rule under each row, no vertical rules and no
  striping, a small uppercase header row. A table wider than the column
  scrolls inside itself, never the page. A right-aligned Markdown column
  (`---:`) takes the quantity treatment, the same as `in-num`.
- A column of code in a table (a name between backticks) stays on one line in
  monospace.
- Lists, nested lists, definition lists (the term in bold, the meaning
  indented behind a rule), blockquotes, code and `pre`, `kbd`, `details` and
  `summary` (a closed `details` is the way to keep supporting detail beside
  the field it explains), footnotes, images, embeds, horizontal rules.
- Task lists (`- [ ]`) keep their checkbox and lose the bullet.
- Forms from the `:::form` syntax: `.lazysite-form`, `.form-field`, labels,
  the required marker, text, number, date, select, textarea and file fields,
  `.form-options` and `.form-option` for checkbox and radio groups (a chosen
  option is marked as a whole), `.form-option-qty`, the submit button as the
  one primary action, `.form-status` (sent and not sent, each by a word and a
  border style as well as colour), the success message, and forms in steps.
- Read-only and disabled fields are dashed on the ground, so a computed field
  is visibly not editable. A focused field has a 2px outline.

## What it does not do

No sticky page header (it fights a table's own sticky header row), no hover
highlight on table rows (it follows the mouse while the eye is on the keyboard
in a table with inputs), no animation, no colour-only signal.

## Light, dark and a second theme

`intranet` follows the device and honours `<html data-theme="light|dark">`.
The colour tokens are in `theme.json` under `colours` and `dark`: `canvas`
(the page behind the panels), `surface`, `sunken`, `ink`, `muted`, `faint`,
`line`, `line-strong`, `band` and its two inks (the gate bar), `accent` and
its hover, ink and soft, `focus-ring`, `ok`, `warn`, `bad` and their soft
tints, `scrim`; plus `fonts` (`body`, `mono`) and `shape`. A second theme, a
high-contrast one for instance, copies `theme.json`, changes values, and lists
`intranet` under `layouts`. It needs no new selector.

## Scripts

One small file, `intranet.js`, opens and closes the section nav on a narrow
screen (the Menu button, closed again by Escape). Without it the nav is listed
above the page.
