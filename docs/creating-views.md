# Creating views for lazysite

A view is a Template Toolkit file (`view.tt`) that controls the visual
presentation of every page on a lazysite site. This guide covers all
the variables, patterns, and conventions needed to create a view.

## Template variables

Every page render passes these variables to `view.tt`:

| Variable | Type | Description |
| -------- | ---- | ----------- |
| `page_title` | string | Page title from front matter. Always set. |
| `page_subtitle` | string | Subtitle from front matter. May be empty. |
| `content` | string | Converted page body as HTML. Output unescaped. |
| `site_name` | string | From `lazysite.conf`. May be empty if not set. |
| `site_url` | string | From `lazysite.conf`. May be empty. |
| `nav` | arrayref | Navigation from `nav.conf`. Empty array if no file. |
| `request_uri` | string | Current page path, e.g. `/about`. |
| `page_modified` | string | Human-readable mtime, e.g. "3 April 2026". |
| `page_modified_iso` | string | ISO 8601 mtime, e.g. "2026-04-03". |
| `theme_assets` | string | Asset path for remote themes, e.g. `/lazysite-assets/default`. Empty for local themes. |
| `query` | hashref | URL query parameters declared in front matter `query_params:`. HTML-escaped. |

Plus any additional variables defined in `lazysite.conf`.

### Auth variables

Set when auth is configured. Always check `[% IF authenticated %]`
before using user-specific variables.

| Variable | Type | Description |
| -------- | ---- | ----------- |
| `authenticated` | boolean | `1` if user is logged in, `0` otherwise. |
| `auth_user` | string | Username from auth header. |
| `auth_name` | string | Display name from auth header. May be empty. |
| `auth_email` | string | Email from auth header. May be empty. |
| `auth_groups` | arrayref | Group names. Iterate with `[% FOREACH g IN auth_groups %]`. |

Example:

```
[% IF authenticated %]
  <span>Signed in as [% auth_name || auth_user %]</span>
  <a href="/logout">Sign out</a>
[% ELSE %]
  <a href="/login">Sign in</a>
[% END %]
```

### Payment variables

Set when a page has `payment: required` in front matter and the
user has been granted access (by payment or group bypass).

| Variable | Type | Description |
| -------- | ---- | ----------- |
| `payment_paid` | boolean | `1` if payment proof was verified. |
| `payment_payer` | string | Payer wallet address if available. |
| `payment_bypassed` | boolean | `1` if access via group membership. |
| `payment_amount` | string | Amount from front matter. |
| `payment_currency` | string | Currency from front matter. |
| `payment_address` | string | Recipient wallet address. |

### Editor and source variables

| Variable | Type | Description |
| -------- | ---- | ----------- |
| `editor` | string | Editor path (e.g. `/editor`) when enabled and user authorised. Empty otherwise. |
| `page_source` | string | Source `.md` path relative to docroot, e.g. `/about.md`. |

Example edit button:

```
[% IF editor %]
<a href="[% editor %]/edit?path=[% page_source %]">Edit</a>
[% END %]
```

### Checking for optional variables

Always test optional variables before using them:

```
[% IF page_subtitle %]<p class="subtitle">[% page_subtitle %]</p>[% END %]
[% IF page_modified %]<time datetime="[% page_modified_iso %]">[% page_modified %]</time>[% END %]
[% IF site_name %]<a href="/">[% site_name %]</a>[% END %]
```

## Navigation pattern

The `nav` variable is an array of hashrefs. Each item has:

- `label` - display text (always present)
- `url` - link target (empty string for non-clickable group headings)
- `children` - array of child items (empty array if none)

Each child has `label` and `url` only.

### Recommended nav loop

```
<nav>
[% FOREACH item IN nav %]
  [% IF item.url %]
  <a href="[% item.url %]"
    [% IF request_uri == item.url %]class="active"[% END %]>
    [% item.label %]</a>
  [% ELSE %]
  <span class="nav-group">[% item.label %]</span>
  [% END %]
  [% IF item.children.size %]
  <ul class="nav-children">
    [% FOREACH child IN item.children %]
    <li><a href="[% child.url %]"
      [% IF request_uri == child.url %]class="active"[% END %]>
      [% child.label %]</a></li>
    [% END %]
  </ul>
  [% END %]
[% END %]
</nav>
```

Use `aria-current="page"` instead of or alongside `class="active"` for
accessibility.

### Empty nav

Always handle the case where `nav` is empty (no `nav.conf` file):

```
[% IF nav.size %]
<nav>
  ...
</nav>
[% END %]
```

## CSS classes

Views should style these elements which appear in rendered page content:

### From Markdown conversion

- `h2` through `h6` - content headings (`h1` is the page title)
- `p` - paragraphs
- `ul`, `ol`, `li` - lists
- `blockquote` - block quotes
- `table`, `thead`, `tbody`, `tr`, `th`, `td` - tables
- `pre`, `code` - code blocks
- `pre > code` - fenced code blocks (language class: `language-bash` etc.)
- `a` - links
- `img` - images
- `strong`, `em` - bold, italic
- `dl`, `dt`, `dd` - definition lists

### From fenced divs

Authors use `:::classname` to wrap content in styled divs. Common classes:

- `widebox` - full-width coloured band
- `textbox` - highlighted box for key points
- `marginbox` - margin pull quote
- `examplebox` - evidence or example highlight

Define CSS for these classes in your view's `<style>` block.

### From oEmbed

- `div.oembed` - embedded media wrapper
- `div.oembed--failed` - failed embed fallback (contains a plain link)

### From includes

- `span.include-error` - invisible by default, expose for debugging:
  ```css
  .include-error::before { content: "include failed: " attr(data-src); color: red; }
  ```

### From forms

- `form.lazysite-form` - form wrapper
- `div.form-field` - field wrapper (label + input)
- `div.form-submit` - submit button wrapper
- `div.form-status` - AJAX status message area
- `p.form-success` - success message after submission
- `span.required` - asterisk on required fields
- `p.auth-error` - login error message
- `form.auth-form` - login form wrapper

### From search

- `div.search-result` - individual result wrapper
- `span.search-tag` - tag badge
- `time.search-date` - date display
- `p.search-subtitle` - result subtitle
- `p.search-excerpt` - result body excerpt
- `mark` - highlighted search term in excerpts

### From features index

- `div.features-layout` - flex container (sidebar + content)
- `nav.features-toc` - sticky sidebar table of contents
- `div.features-content` - main content area
- `div.feature-entry` - individual feature section

## Theme metadata

Include a TT comment block at the top of `view.tt`:

```
[%#
  name: My Theme
  version: 1.0.0
  author: Your Name
  requires: 0.9.0
  description: Brief description of the theme.
%]
```

This is for documentation only - the processor does not parse it.

## Minimal working view

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[% page_title %][% IF site_name %] - [% site_name %][% END %]</title>
</head>
<body>
[% IF nav.size %]
<nav>
[% FOREACH item IN nav %]
  [% IF item.url %]<a href="[% item.url %]">[% item.label %]</a>[% END %]
[% END %]
</nav>
[% END %]
<main>
    <h1>[% page_title %]</h1>
    [% IF page_subtitle %]<p>[% page_subtitle %]</p>[% END %]
    [% content %]
</main>
<footer>
    <p>Built with <a href="https://lazysite.io">lazysite</a></p>
</footer>
</body>
</html>
```

## Self-contained views

Views should be self-contained - all CSS inline in a `<style>` block,
no external dependencies. This ensures the view works immediately after
installation without needing to fetch additional files.

Use system fonts:

```css
body { font-family: system-ui, -apple-system, sans-serif; }
code, pre { font-family: ui-monospace, 'Cascadia Code', monospace; }
```

## Testing a view

Test with a mock variables hash:

```perl
perl -e '
use Template;
my $tt = Template->new(ABSOLUTE => 0);
my $vars = {
    page_title    => "Test Page",
    page_subtitle => "A subtitle",
    content       => "<p>Hello world</p><pre><code>code block</code></pre>",
    site_name     => "Test Site",
    site_url      => "http://localhost",
    nav           => [
        { label => "Home", url => "/", children => [] },
        { label => "About", url => "/about", children => [] },
        { label => "Resources", url => "", children => [
            { label => "GitHub", url => "https://github.com" },
        ]},
    ],
    request_uri   => "/",
    page_modified => "1 April 2026",
    page_modified_iso => "2026-04-01",
};
my $out = "";
$tt->process("view.tt", $vars, \$out) or die $tt->error();
print $out;
' > /tmp/test-output.html
```

Check:
- Valid HTML5 (`<!DOCTYPE html>`)
- Title contains page title and site name
- Content present
- Navigation renders with active state
- Non-clickable nav parents render as plain text
- Empty nav renders gracefully
- Footer present

## Theme switching

lazysite supports a cookie-based theme switcher that allows visitors
to switch between installed themes. The switcher is implemented in
the view template itself - the processor reads the cookie and resolves
the appropriate theme.

### How it works

1. Visitor clicks the theme switcher button
2. JS sets the `lazysite_theme` cookie to the next theme name
3. Page reloads
4. Processor reads the cookie in `get_layout_path()` and serves the
   named theme's `view.tt`

Cookie priority in the processor:

    layout: front matter > lazysite_theme cookie > theme: in lazysite.conf > default view.tt

### Declaring available themes

Each view declares which themes it participates in via the `themes`
array in the switcher JS:

    const themes = ['default', 'dark'];

Add theme names to this array to make them available in the switcher.
Themes are cycled in order - clicking the button advances to the next
theme, wrapping around at the end.

### Adding a new theme variant

To add a `high-contrast` theme:

1. Create `lazysite-views/high-contrast/view.tt` with appropriate CSS
2. Install it at `public_html/lazysite/themes/high-contrast/view.tt`
3. Add `'high-contrast'` to the `themes` array in each participating view
4. Add a label entry: `'high-contrast': 'Switch to high contrast'`

Any number of theme variants can be added. Common accessibility variants:

`high-contrast`
: Black background, white text, no gradients. For users with visual
  impairment or in bright environments.

`large-text`
: Same palette as default but larger base font size and increased
  line height. For users who need larger text without browser zoom.

`reduced-motion`
: Disables CSS transitions and animations. For users with vestibular
  disorders or motion sensitivity.

### Cookie properties

    Name:     lazysite_theme
    Value:    theme name (e.g. dark, high-contrast)
    Path:     / (site-wide)
    Max-age:  31536000 (one year)
    SameSite: Lax

The cookie is set and read entirely client-side for the button
interaction. The processor reads it server-side via `$ENV{HTTP_COOKIE}`
to resolve the correct `view.tt` at render time.

### No-JS fallback

When JavaScript is unavailable, the button renders with static text
"Switch theme" and clicking it has no effect. The site remains fully
functional - visitors simply cannot switch themes without JS.

## Directory structure

A view directory contains:

```
viewname/
  view.tt      <- the view template (required)
  nav.conf     <- example navigation (optional)
```

The `nav.conf` is a convenience for users - it shows the nav format
but is not used by the processor directly.

## Packaging a theme for distribution

Use the packager script to build an installable zip:

    bash tools/package-themes.sh

This validates required files and creates `releases/THEMENAME.zip`
in the correct format for the lazysite editor upload.

### Manual packaging

The zip must be flat (no containing directory) and include at minimum:

    view.tt
    theme.json

Optionally:

    nav.conf
    assets/main.css
    assets/ (other files)

The `theme.json` `name` field must match the directory name. If the
name conflicts with an existing theme during editor upload, the
install directory is prefixed with the date.
