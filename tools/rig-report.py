#!/usr/bin/env python3
"""rig-report.py - turn the rig's results into the catalogue measurement report.

  rig-report.py <rig-dir> <out.md> <engine-version> <route> <run-date> <command>

Reads <rig-dir>/results.json and <rig-dir>/states.json (the measure and states
steps) and writes one markdown file: a summary of counts, one row per layout
and theme, the states groups, and the nav and favicon proof per layout.
"""
import collections, json, os, sys

rig, out, engine, route, date, command = sys.argv[1:7]
res = json.load(open(os.path.join(rig, 'results.json')))
sta = json.load(open(os.path.join(rig, 'states.json')))
themes = res['themes']
proof = res['proof']
NCHILD = 8
STATE_GROUPS = ['link hover', 'link keyboard focus', 'visited links', 'button hover', 'button keyboard focus',
                'disabled button', 'field focus', 'invalid fields', 'placeholder text', 'checked boxes and radios',
                'form messages', 'form success', 'form steps', 'disclosures', 'reduced motion']

def esc(s):
    return str(s).replace('|', '\\|')

def scroll_cell(r, page):
    """widths at which the page scrolls sideways (any scheme), with the worst overflow."""
    bits = []
    for w in (390, 1280):
        worst, schemes = 0, []
        for sch in ('light', 'dark'):
            m = r['scroll'].get('%s-%d-%s' % (page, w, sch))
            if m and m['sw'] > m['cw'] + 1:
                worst = max(worst, m['sw'] - m['cw'])
                schemes.append(sch)
        if schemes:
            tag = '' if len(schemes) == 2 else ' (%s only)' % schemes[0]
            bits.append('%d +%dpx%s' % (w, worst, tag))
    return '; '.join(bits) if bits else 'no'

def scrolls(r, page):
    return any(m['sw'] > m['cw'] + 1 for k, m in r['scroll'].items() if k.startswith(page + '-'))

def culprit(r):
    for k in ('spec-390-light', 'spec-1280-light', 'steps-390-light', 'steps-1280-light',
              'spec-390-dark', 'spec-1280-dark', 'steps-390-dark', 'steps-1280-dark'):
        m = r['scroll'].get(k)
        if m and m.get('culprit'):
            c = m['culprit']
            cls = (c['cls'] or '').split()
            return c['tag'] + ('.' + cls[0] if cls else '')
    return ''

def nav_verdict(r):
    n = r['nav1280']
    if not n['found']:
        return 'none', 'no nav rendered'
    rules = n['themeRules'] + n['inlineRules']
    if not r['top1280']['visible']:
        return 'collapsed', 'the whole nav is hidden at 1280'
    bullets = n['listStyle'] not in (None, 'none')
    vis = n['visible']
    if vis == 0:
        return 'menu', 'closed by default, %d rule(s)' % rules
    if vis < n['found']:
        return 'partial', '%d of %d visible, %d rule(s)' % (vis, n['found'], rules)
    if bullets:
        return 'open-unstyled', 'all %d open, bullets (%s), %dpx tall, %d rule(s)' % (vis, n['listStyle'], n['rootH'], rules)
    if rules == 0:
        return 'open-unstyled', 'all %d open, no rule matches %s, %dpx tall' % (vis, '/'.join(n['classes'][:3]) or 'its classes', n['rootH'])
    return 'open-styled', 'all %d open, %dpx tall, %d rule(s)' % (vis, n['rootH'], rules)

def form_verdict(r):
    f = r['form']
    if not f['labels']:
        return 'none', 'no form options rendered'
    rules = f['optRulesTheme'] + f['optRulesInline']
    sig = (f['border'] or 0) > 0 and (f['widthRatio'] or 0) > 0.9 or (f['boxW'] or 0) > 40
    if rules:
        return 'styled', '%d rule(s)%s' % (rules, ', still full-width bordered' if sig else '')
    return ('unstyled-signature' if sig else 'unstyled'), (
        'no rule; each option full-width with a border' if sig else 'no .form-option rule')

def mobile(r):
    if not r['nav390']['found']:
        return 'none'
    if not r.get('toggle390'):
        return 'no toggle; %d of %d visible' % (r['nav390']['visible'], r['nav390']['found'])
    o = r.get('nav390open')
    if not o:
        return 'toggle, no read'
    b = o['listStyle'] not in (None, 'none')
    return 'toggle opens: %d of %d visible%s' % (o['visible'], o['found'], ', bullets' if b else '')

rows = []
c = collections.Counter()
culp = collections.Counter()
state_missing = collections.Counter()
for key, r in themes.items():
    nv, nd = nav_verdict(r)
    fv, fd = form_verdict(r)
    ic = r['icon']
    icon_ok = bool(ic.get('href')) and ic.get('status') == 200 and 'svg' in (ic.get('type') or '')
    s = sta.get(key, {'states': [], 'other': []})
    sp, st = scrolls(r, 'spec'), scrolls(r, 'steps')
    c['scroll_any'] += sp or st
    c['scroll_spec'] += sp
    c['scroll_steps'] += st
    c['nav_' + nv] += 1
    c['form_' + fv] += 1
    c['form_styled'] += fv == 'styled'
    c['icon_ok'] += icon_ok
    c['states_clean'] += not s['states']
    c['states_total'] += len(s['states'])
    f = r['form']
    c['any_form_rule'] += (f['anyFormRulesTheme'] + f['anyFormRulesInline']) > 0
    c['any_form_rule_theme'] += f['anyFormRulesTheme'] > 0
    if sp or st:
        culp[culprit(r)] += 1
    for g in s['states']:
        state_missing[g] += 1
    rows.append((key, scroll_cell(r, 'spec'), scroll_cell(r, 'steps'), culprit(r), nv, nd + '; 390: ' + mobile(r), fv, fd, icon_ok, ic, s))
    c['mob_bullets'] += bool(r.get('nav390open') and r['nav390open']['visible'] and r['nav390open']['listStyle'] not in (None, 'none'))
    c['mob_open'] += bool(r.get('nav390open') and r['nav390open']['visible'] == r['nav390open']['found'] and r['nav390open']['found'])

n = len(rows)
L = []
w = L.append
w('# Catalogue baseline, %s' % date)
w('')
w('One row per layout and theme, measured by `tools/render-catalogue.sh` against the design-kit specimen '
  'and the form in steps. Re-run the same command for the after measurement.')
w('')
w('```')
w(command)
w('```')
w('')
w('Engine: lazysite %s (the dev server, `tools/lazysite-server.pl`, rendering the real processor).' % engine)
w('Route: %s' % route)
w('')
w('## Summary of counts')
w('')
w('| Measure | Count |')
w('|---|---|')
w('| Themes measured (layouts) | %d (%d) |' % (n, len({k.split('/')[0] for k in themes})))
w('| Scroll sideways on the specimen at 390 or 1280, either scheme | %d of %d |' % (c['scroll_spec'], n))
w('| Scroll sideways on the form in steps | %d of %d |' % (c['scroll_steps'], n))
w('| Scroll sideways on either page | %d of %d |' % (c['scroll_any'], n))
w('| Nested nav drawn as open lists (unstyled) | %d of %d |' % (c['nav_open-unstyled'], n))
w('| Nested nav a closed menu | %d of %d |' % (c['nav_menu'], n))
w('| Nested nav open but styled (bar or sidebar) | %d of %d |' % (c['nav_open-styled'], n))
w('| Nested nav partly visible | %d of %d |' % (c['nav_partial'], n))
w('| Mobile menu opened by its toggle shows every child | %d of %d |' % (c['mob_open'], n))
w('| Mobile menu opened shows children as bullet lists | %d of %d |' % (c['mob_bullets'], n))
w('| No nav rendered (demonstration layout) | %d of %d |' % (c['nav_none'], n))
w('| Style `.form-option` or `.form-options` | %d of %d |' % (c['form_styled'], n))
w('| Style any `.form-*` class (theme sheet) | %d of %d |' % (c['any_form_rule_theme'], n))
w('| Unstyled option signature (full-width, bordered option) | %d of %d |' % (c['form_unstyled-signature'], n))
w('| Favicon link resolves 200 as SVG | %d of %d |' % (c['icon_ok'], n))
w('| Themes with every STATES.md group styled | %d of %d |' % (c['states_clean'], n))
w('| Unstyled state groups, total | %d |' % c['states_total'])
w('')
if culp:
    w('First culprit of the sideways scroll, by element: ' + ', '.join('`%s` (%d)' % (k, v) for k, v in culp.most_common()) + '.')
    w('')

w('## Per layout and theme')
w('')
w('Scroll cells give the width and how far the document is wider than the window, in either scheme. '
  'The nav cell reads the rendered `[%% nav %%]` at 1280: closed menu, open and styled, or open and unstyled. '
  'The form cell is the `.form-option` / `.form-options` rule count in the theme sheet and the layout head. '
  'States is the number of the %d STATES.md groups with no style in `assets/main.css`.' % len(STATE_GROUPS))
w('')
w('| Layout / theme | Specimen scroll | Steps scroll | First culprit | Nested nav | Form options | Favicon | States unstyled |')
w('|---|---|---|---|---|---|---|---|')
for key, sp, st, cu, nv, nd, fv, fd, iok, ic, s in rows:
    icon = ('%s %s' % (ic.get('status'), (ic.get('type') or '').replace('image/', ''))) if ic.get('href') else 'no link'
    w('| %s | %s | %s | %s | %s: %s | %s: %s | %s | %d |' % (
        key, esc(sp), esc(st), esc('`%s`' % cu if cu else '-'), nv, esc(nd), fv, esc(fd), icon, len(s['states'])))
w('')

w('## States left unstyled')
w('')
w('`lzs-design-kit.sh check <theme-folder>` on the pack as built. Run without a site, so the comparison with '
  'a site\'s kit tokens is skipped; everything else in the check runs. The check reads `assets/main.css` and `assets/base.css`, '
  'so a state the layout styles in its own head still counts as unstyled here.')
w('')
w('| State group | Themes without a style |')
w('|---|---|')
for g in STATE_GROUPS:
    w('| %s | %d of %d |' % (g, state_missing[g], n))
w('')
w('Per theme, the groups with no style:')
w('')
w('| Layout / theme | Groups unstyled |')
w('|---|---|')
for key, *_rest, s in rows:
    w('| %s | %s |' % (key, esc(', '.join(s['states']) or 'none')))
w('')
oth = collections.Counter()
for key, s in sta.items():
    for o in s['other']:
        oth[o if not o.startswith('main.css uses') and not o.startswith('kit tokens') else o.split(',')[0][:60]] += 1
w('Other failures the check reports (counts of themes). The first three describe a design-kit return folder '
  '(notes and brand icons) rather than a catalogue pack:')
w('')
w('| Failure | Themes |')
w('|---|---|')
for o, v in oth.most_common():
    w('| %s | %d |' % (esc(o), v))
w('')

w('## Nav and favicon proof, per layout (the 24/08 filing)')
w('')
w('Each layout rendered a plain non-home page (`/contact`) on the rig with a nav of four top-level links, '
  'three groups and eight children. `Missing` lists labels or URLs not present as links. `Active` is the marker '
  'on the current page\'s item (top level on `/contact`, child on `/docs/authoring`). `Icon` is the declared '
  '`<link rel="icon">` href and what it returned. `No theme` pins a theme that does not exist.')
w('')
w('| Layout | Missing | Active top / child | `#fragment` links | Icon | No theme |')
w('|---|---|---|---|---|---|')
ok_nav = 0
site_layouts = 0
LDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'layouts')
def kind(lay):
    try:
        return json.load(open(os.path.join(LDIR, lay, 'layout.json'))).get('kind', 'site')
    except Exception:
        return 'site'
for lay, p in sorted(proof.items()):
    if kind(lay) != 'demonstration':
        site_layouts += 1
    miss = ', '.join(p['missing']) if p['missing'] else 'none'
    if kind(lay) == 'demonstration':
        miss = 'demonstration layout, no nav by design'
    else:
        ok_nav += (not p['missing'])
    ic, nt = p['icon'], p['icon_notheme']
    def ics(i):
        return ('`%s` %s %s' % (i['href'], i['status'], i['type'])) if i.get('href') else 'no link'
    w('| %s | %s | %s / %s | %s | %s | %s |' % (
        lay, esc(miss), 'yes' if p['active_top'] else 'no', 'yes' if p['active_child'] else 'no',
        esc(', '.join(p['fragments']) or 'none'), esc(ics(ic)), esc(ics(nt))))
w('')
w('%d of %d site layouts (the demonstration layout, `explorer`, is exempt) render every configured label and URL on a non-home page.' % (ok_nav, site_layouts))
u = res.get('unthemed', {})
w('')
w('A layout with no `default_theme` and no resolving theme (a copy of the `default` template with no `layout.json`): '
  + ('the icon link is `%s`, which returned %s %s.' % (u['href'], u['status'], u['type']) if u.get('href') else 'no icon link is emitted.'))
w('')

w('## What this run does not measure')
w('')
w('- Hover, focus, visited, disabled, invalid and checked states are counted from the stylesheet text by the check, '
  'never exercised in a browser.')
w('- No layout in the catalogue carries a `data-theme` switcher, so dark is measured by device-scheme emulation, '
  'with `data-theme="dark"` also set on `<html>` for the scroll measure.')
w('- The nested nav is judged at 1280 and 390 on the rendered links only; a menu opened by hover or by the mobile '
  'toggle is not opened.')
w('- The kit-token comparison in `check` needs a site\'s published kit and is skipped.')
w('- The specimen\'s oEmbed block and QR code are static markup here; scripts the layouts load run as in a browser.')
w('')
open(out, 'w').write('\n'.join(L) + '\n')
print('wrote', out)
