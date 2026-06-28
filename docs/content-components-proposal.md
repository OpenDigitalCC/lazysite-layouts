# Proposal: content components — simple Markdown, theme-owned design

Status: COMPLETE. Phase 1 (0.4.64), Phase 2 fenced components (0.4.65), and
Phase 3 front-matter `sections:` (0.4.66) are all SHIPPED - see the
"... - available now" sections below.
Audience: lazysite core (processor) maintainer + layout authors
Problem owner: themes like `nova`, `pulse`, `press` are HTML-heavy

## The problem

Expressive layouts (nova, pulse, press, console, the dashboards) only look
right because the **content page** carries a slab of bespoke HTML — hero
scaffolding, glass panels, mosaic tiles, canvas elements, ticker markup.
That breaks the D013 promise: an author who wants a nova page has to hand-write
nova's structure, and a single stray blank line or a `#`-leading `<style>` line
silently corrupts the render (see the authoring gotchas).

We want the inverse: **the author writes simple Markdown; the layout/theme
frames it in the heavy HTML.** Design must not be compromised — the component
author keeps full HTML/CSS/JS power — but the *content* surface becomes Markdown
plus a little light structure.

## The principle (where things live under D013)

- **Structure is the layout's job.** nova's hero markup is *structure*, so it
  belongs in the **layout**, not in the content page and not in the theme.
- **Appearance is the theme's job.** The theme styles the component's class
  names with tokens (`--theme-colours-*`) and `main.css`. No colours in the
  component HTML.
- **Content is Markdown + light structure.** The author names a component and
  fills it; they never see the scaffolding.

So the unit we are introducing is a **component: a named partial owned by the
layout**, styled by the theme, invoked from content.

## Author experience

### Recommended: fenced components (extends the existing `:::` syntax)

lazysite already turns `::: widebox` into a styled wrapper. Generalise it: an
unknown fence name resolves to a layout component, the **inner Markdown is
rendered and handed to the component as `content`**, and key/value lines on the
opening fence become parameters.

**Before** — today's nova hero, authored as raw HTML in the page body:

```html
<section class="hero"><canvas id="pulse-canvas"></canvas>
<div class="hero-inner"><span class="eyebrow">Generative · Interactive</span>
<h1 class="display">A site that's <span class="grad-text">alive</span>.</h1>
<p class="lead">The field behind these words is drawn live …</p>
<div class="cta"><a class="btn primary" href="#concept">How it works</a>
<a class="btn" href="#start">Get started</a></div></div></section>
```

**After** — the same page, authored in Markdown:

```markdown
::: hero  eyebrow="Generative · Interactive"
# A site that's *alive*.

The field behind these words is drawn live — particles flowing through a
procedural current, reacting to your cursor.

::: actions
[How it works](#concept){.primary}
[Get started](#start)
:::
:::
```

The author writes a heading, a paragraph, two links. The **component** supplies
the `<section class="hero">`, the canvas, the `.hero-inner` wrapper, the
`.grad-text` emphasis (mapped from Markdown `*emphasis*`), and the button
classes. Nested fences (`::: actions`) are **named slots**.

The component that backs it (shipped with the layout):

```tt
[%# layouts/nova/components/hero.tt %]
<section class="hero">
  <canvas id="pulse-canvas"></canvas>
  <div class="hero-inner">
    [% IF attrs.eyebrow %]<span class="eyebrow">[% attrs.eyebrow %]</span>[% END %]
    [% content %]
    [% IF slots.actions %]<div class="cta">[% slots.actions %]</div>[% END %]
  </div>
</section>
```

`content` is the rendered inner Markdown (so `# …` became the `<h1>`,
`*alive*` became `<em>` which the theme styles as the gradient word); `attrs`
are the opening-line params; `slots` are the named nested fences.

This is the sweet spot: pure-Markdown authoring, the existing `:::` mental
model, and the design stays 100% in the component + CSS.

### Complementary: front-matter `sections:` (data-driven whole pages)

For landing pages that are *all* structure, let the page describe itself as
data and let the layout render it:

```yaml
---
title: NOVA
sections:
  - hero:
      eyebrow: Generative · Interactive
      heading: "A site that's *alive*."
      lead: The field behind these words is drawn live …
      actions:
        - { label: How it works, href: '#concept', style: primary }
        - { label: Get started,  href: '#start' }
  - feature-grid:
      items:
        - { icon: spark, title: No framework, body: "Native CSS and a little JS." }
        - { icon: bolt,  title: Instant,      body: "No build, no database." }
---
```

The layout iterates and dispatches each section to its component:

```tt
[% FOREACH s IN sections %]
  [% type = s.keys.first %]
  [% INCLUDE "components/$type.tt" data = s.$type %]
[% END %]
[% content %]   [%# any Markdown body still renders below the sections %]
```

Same components, two front doors: **fences** for Markdown-with-occasional-design,
**`sections:`** for fully-composed pages.

## What already works (probed against lazysite 0.4.60)

I staged a throwaway `probe` layout and rendered pages through it. Findings:

| Capability | Status on 0.4.60 |
| --- | --- |
| `::: name` → `<div class="name">…</div>` around the inner block | **Works.** Any fence name already becomes a class-wrapped div. |
| Markdown *inside* a fence | **Unreliable.** A simple paragraph renders; a `##` heading came through literal. |
| Nested fences (a `hero` containing an `actions` slot) | **No.** The first `:::` closes the block; the inner fence is left as literal text. |
| `::: include /path` | **No.** Rendered literally, even when closed. (The For-AI guide's claim is wrong and should be corrected.) |
| TT `INCLUDE 'components/x.tt'` from `layout.tt` | **Directive runs, but file not found** — `INCLUDE_PATH` is not set to the layout dir. |
| `[% value | markdown %]` filter | **No** — "filter not found". |
| Nested front-matter (`sections:` list-of-maps, `probe.a`) exposed to TT | **No.** Only top-level scalar front-matter keys reach the layout. |

So the **only** zero-change mechanism today is a *flat* `::: name` wrapper styled
by CSS. That already buys a lot (a theme can ship `.hero`, `.callout`, `.cta`
styling and authors write `::: hero`), but it cannot inject scaffolding (canvas,
nested glass panels), cannot carry slots, and cannot reliably contain block
Markdown. Everything richer needs the changes below — each row above maps
directly to one.

## What the engine must add

Minimal-first; each tier is independently shippable. (Status column = the probe
result that motivates it.)

1. **Component resolution + `INCLUDE_PATH`.** Set Template Toolkit's
   `INCLUDE_PATH` to the active layout's directory so `layout.tt` (and other
   components) can `[% INCLUDE 'components/NAME.tt' %]`. Discover
   `layouts/<layout>/components/*.tt`. *(This alone unlocks the `sections:`
   approach with a hand-written dispatch loop.)*

2. **Fenced-name → component.** In the fenced-div parser, when a fence name is
   not a built-in (`widebox`…), look for `components/<name>.tt`. If found:
   - render the inner block **as Markdown → HTML**, pass it as `content`;
   - parse `key="value"` pairs on the opening line into `attrs`;
   - render nested fences whose names are not components as **named slots**
     (`slots.<name>` = their rendered Markdown);
   - `PROCESS` the component with `{ content, attrs, slots }` plus the normal
     page vars (`theme`, `nav`, `request_uri`, …).
   Unknown name with no component → today's behaviour (or a visible build note),
   never a silent drop.

3. **A `markdown` filter / vmethod.** Expose `[% value | markdown %]` so a
   component can render a field that contains inline Markdown
   (`heading="…*alive*…"`). This is what lets fields stay Markdown, not HTML.

4. **Front-matter `sections:` exposure (for the data-driven door).** Parse a
   list-of-maps in front matter and expose it to the layout as `sections`
   (nested maps/lists must survive parsing — confirm the current YAML subset
   handles this; extend if not). No new render path is needed beyond (1).

5. **Optional: a `component()` helper** so `sections:` dispatch is one call
   rather than the `INCLUDE "$type"` dance, and so an unknown type degrades to a
   logged note instead of a TT error.

Nothing here changes the theme contract: components consume `--theme-*` tokens
through their class names exactly as `main.css` does today.

## Why this doesn't compromise design

The component author writes whatever HTML/CSS/JS the design needs — the
ceiling is unchanged. What changes is **who** writes it: once, in the layout's
component library, instead of in every content page. The content author's
surface shrinks to Markdown + a fence name + a few fields. As a bonus it
**closes two of the worst authoring gotchas**: authors stop hand-pasting raw
HTML and inline `<style>`, so the "blank-line splits my wrapper" and
"`#`-line becomes an `<h1>`" traps disappear from content entirely.

## Packaging implications

- The layout package (`releases/layouts/<layout>.zip`) gains a `components/`
  subtree alongside `layout.tt` / `layout.json`. `package-layouts.sh` includes
  it; `manifest.json` is unaffected (components travel inside the layout zip).
- A component may ship its own JS (e.g. the pulse canvas). Keep colours out of
  it — read `--theme-colours-*` via `getComputedStyle`, per the pulse/chroma
  reference.

## Security

Content authors invoke components by **name** and fill **data/Markdown slots** —
they never write Template Toolkit. The fence/`sections` path must treat all
author input as data (no `[% %]` execution from content), and render slot bodies
through the Markdown pipeline (which already escapes/limits raw HTML per the
site's policy). Component templates are authored by the trusted layout author
and travel in the signed layout package.

## Suggested phasing

1. **Phase 1** — engine items (1)+(3): `INCLUDE_PATH` + `markdown` filter.
   Ship a `components/` in one layout (nova), rewrite the nova demo page using
   `sections:` with a hand-written dispatch loop. Proves the model with the
   smallest engine change.
2. **Phase 2** — engine item (2): fenced components. Convert the nova/pulse/press
   demo pages to pure Markdown with `::: hero` etc. Author-facing win.
3. **Phase 3** — item (5) + docs: the `component()` helper, named-slot
   conventions, and a per-layout "components reference" page in the theme guide.

## Concrete first step I can take in this repo

On request I will: add `layouts/nova/components/{hero,feature-grid}.tt`, move the
hero/grid HTML out of the nova demo page into those components, and provide both
a `sections:`-based and a `:::`-based version of the demo page — so the moment
engine items (1)/(3) (then (2)) land, nova is the worked reference for every
other layout to copy.

## Phase 1 - available now (lazysite 0.4.64)

The two engine pieces a layout author can use today:

1. **Layout-local components.** The layout template engine's `INCLUDE_PATH` is the
   active layout's own directory, so `layout.tt` (and any component) can pull in
   partials:

   ```tt
   [% INCLUDE 'components/hero.tt' eyebrow = 'Generative' %]
   ```

   Put them under `layouts/<layout>/components/*.tt`. They render with the normal
   page vars (`theme`, `nav`, `request_uri`, `content`, ...) plus any `key = value`
   you pass on the INCLUDE. `EVAL_PERL` stays off; components travel inside the
   layout package, so they go in the layout zip automatically.

2. **`markdown` filter.** Render a value that contains Markdown:

   ```tt
   <h1>[% heading | markdown %]</h1>      [%# A site that's <em>alive</em>. %]
   [% body | markdown %]                  [%# full block Markdown -> HTML %]
   ```

   A single-paragraph value is unwrapped (inline, no `<p>`); multi-paragraph
   content keeps its block structure. Works inside components too.

What this enables right now: move a layout's bespoke hero/grid HTML out of the
demo page into `components/*.tt`, and drive them from a hand-written dispatch in
`layout.tt`. Keep colours in CSS tokens (`--theme-colours-*`), never in the
component HTML.

**Not yet** (later phases, tracked in lazysite): the `::: hero` fenced-component
author syntax, and front-matter `sections:` (needs a nested-YAML parser - the
current front-matter subset is flat). Author-facing Markdown invocation lands
with those; Phase 1 is the layout-author foundation.

Concrete next step (yours): add `layouts/nova/components/{hero,feature-grid}.tt`,
move that HTML out of the nova demo page, and have `nova/layout.tt` INCLUDE them -
so nova is the worked reference the moment fenced components land.

## Phase 2 - available now (lazysite 0.4.65)

Authors can invoke a component straight from Markdown. A `::: <name>` fence whose
`<name>` matches `layouts/<layout>/components/<name>.tt` is rendered through that
component:

- the inner Markdown becomes **`content`**,
- `key="value"` (or `key='value'`) pairs on the opening line become **`attrs`**,
- direct-child `::: <slot>` fences become **`slots.<slot>`** (rendered Markdown).

Author writes:

    ::: hero eyebrow="Generative · Interactive"
    # A site that's *alive*.

    The field behind these words is drawn live.

    ::: actions
    [How it works](#concept)
    [Get started](#start)
    :::
    :::

`layouts/nova/components/hero.tt` supplies the scaffolding:

    <section class="hero">
      <canvas id="pulse-canvas"></canvas>
      <div class="hero-inner">
        [% IF attrs.eyebrow %]<span class="eyebrow">[% attrs.eyebrow %]</span>[% END %]
        [% content %]
        [% IF slots.actions %]<div class="cta">[% slots.actions %]</div>[% END %]
      </div>
    </section>

Notes and current limits:

- A fence name with **no** matching component is unchanged - it still becomes a
  `<div class="name">` (the old behaviour), so nothing existing breaks.
- Nesting is handled (a component can contain slot fences). **Not yet**: a
  component *inside* another component's content/slot, and `::: include` inside a
  component - both later. Keep components one level deep for now.
- Components render with `EVAL_PERL` off and the layout dir on `INCLUDE_PATH`, so
  a component may `[% INCLUDE 'components/other.tt' %]` and use `[% x | markdown %]`.
- Local layouts only (a remote/URL layout skips component resolution for now).

What's left: front-matter `sections:` (data-driven whole pages) needs a nested-YAML
parser - the only remaining engine piece.

## Phase 3 - available now (lazysite 0.4.66)

A page can describe itself as data and let the layout compose it:

    ---
    title: NOVA
    sections:
      - hero:
          eyebrow: Generative
          heading: "A site that's *alive*."
          actions:
            - { label: How it works, href: '#concept', style: primary }
            - { label: Get started,  href: '#start' }
      - feature-grid:
          items:
            - { title: No framework, body: "Native CSS and a little JS." }
    ---

The front-matter `sections:` is a sequence of single-key maps (the key is the
component name) parsed into the `sections` variable. The layout dispatches each:

    [% FOREACH s IN sections %]
      [% type = s.keys.first %]
      [% INCLUDE "components/${type}.tt" data = s.$type %]
    [% END %]
    [% content %]   [%# any Markdown body still renders below %]

and each component reads from `data` (use the `markdown` filter for Markdown
fields, e.g. `[% data.heading | markdown %]`).

IMPORTANT - dispatch must use **`${type}.tt`** (braces). Bare `$type.tt` is parsed
by Template Toolkit as the dotted variable `type.tt` (→ empty) and the INCLUDE
fails. This is the one gotcha; copy the loop above verbatim.

Supported in `sections:` data: nested maps, nested sequences, inline flow maps
`{k: v, ...}` and seqs `[a, b]`, quoted and bareword scalars. It is a small
purpose-built subset, not general YAML - keep to the shapes shown.

Two front doors now exist for the same components: **fenced `::: name`** for
Markdown-with-occasional-design (Phase 2), and **`sections:`** for fully-composed
pages (Phase 3). Content components are complete.
