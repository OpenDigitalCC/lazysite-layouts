#!/usr/bin/env python3
"""rig-measure.py - measure every catalogue theme on the local rig.

  rig-measure.py <rig-dir> [--only layout/theme ...] [--base http://127.0.0.1:8097] [--port 9333]

Needs the rig site served (render-catalogue.sh starts it) and a headless
Chromium listening on the CDP port. Writes <rig-dir>/results.json and
screenshots under <rig-dir>/shots/. Loopback only; no other network access.

Per theme, on the specimen page and the form-in-steps page, at 390 and 1280
wide, in light and dark (CDP prefers-color-scheme emulation): sideways scroll
and its first culprit. On the specimen at 1280: nested-nav state, the form
option classes, the favicon. The nav and favicon proof for the 24/08 filing
(per layout, plain HTTP) is run last.
"""
import json, os, re, subprocess, sys, time, urllib.request, urllib.error

sys.path.insert(0, '/srv/projects/odoo/oom/lazysite-oom-dev/bin')
from cdp_tab import Tab  # the shared CDP tab helper (read-only reference)

args = sys.argv[1:]
RIG = args.pop(0)
BASE, PORT, ONLY = 'http://127.0.0.1:8097', 9333, []
while args:
    a = args.pop(0)
    if a == '--base': BASE = args.pop(0)
    elif a == '--port': PORT = int(args.pop(0))
    elif a == '--only': ONLY.append(args.pop(0))
    else: sys.exit('unknown option ' + a)

DOC = os.path.join(RIG, 'docroot')
SHOTS = os.path.join(RIG, 'shots')
os.makedirs(SHOTS, exist_ok=True)

themes = [l.rstrip('\n').split('\t') for l in open(os.path.join(RIG, 'themes.tsv')) if l.strip()]
if ONLY:
    themes = [t for t in themes if '%s/%s' % tuple(t) in ONLY]

TOP_HREFS = ['/s/default/default', '/f/default/default']
CHILD_HREFS = ['/docs/authoring', '/docs/features', '/docs/api', '/docs/configuration',
               '/docs/reference', '/docs/themes', '/docs/install', '/docs/development']

JS_SCROLL = r"""
(function(){
 var de=document.documentElement, o={sw:de.scrollWidth, cw:de.clientWidth, culprit:null};
 if(o.sw<=o.cw+1) return o;
 function fixed(e){for(;e&&e!==document.documentElement;e=e.parentElement){if(getComputedStyle(e).position==='fixed')return true;}return false;}
 function clipped(e){for(var p=e.parentElement;p&&p!==document.body&&p!==de;p=p.parentElement){
   if(getComputedStyle(p).overflowX!=='visible'){var r=p.getBoundingClientRect();if(r.right<=o.cw+1)return true;}}return false;}
 var all=document.body.getElementsByTagName('*'), hit=[], set=new Set();
 for(var i=0;i<all.length;i++){var e=all[i], r=e.getBoundingClientRect();
   if(!r.width&&!r.height)continue;
   if(r.right>o.cw+1 && !fixed(e) && !clipped(e)){hit.push(e);set.add(e);}}
 for(var j=0;j<hit.length;j++){var e=hit[j], deeper=false;
   for(var k=0;k<e.children.length;k++){if(set.has(e.children[k])){deeper=true;break;}}
   if(!deeper){var r=e.getBoundingClientRect();
     o.culprit={tag:e.tagName.toLowerCase(), cls:(e.className&&e.className.baseVal===undefined?e.className:'')||'', right:Math.round(r.right),
       text:(e.textContent||'').trim().slice(0,28)};break;}}
 return o;
})()
"""

JS_NAV = r"""
(function(hrefs){
 var o={found:0, visible:0, listStyle:null, rootTag:null, rootCls:null, rootH:null, themeRules:0, inlineRules:0, classes:[]};
 function vis(e){
   var r=e.getBoundingClientRect(); if(r.width<1||r.height<1) return false;
   for(var p=e;p&&p!==document.documentElement;p=p.parentElement){
     var s=getComputedStyle(p);
     if(s.display==='none'||s.visibility==='hidden'||parseFloat(s.opacity)<0.05) return false;
     if(p!==e && (s.overflowX!=='visible'||s.overflowY!=='visible')){
       var q=p.getBoundingClientRect();
       if(q.width<1||q.height<1||r.bottom<=q.top||r.top>=q.bottom||r.right<=q.left||r.left>=q.right) return false;}
   }
   return r.right>0 && r.left<window.innerWidth;
 }
 var first=null;
 hrefs.forEach(function(h){var a=document.querySelector('a[href="'+h+'"]'); if(!a)return; o.found++; if(!first)first=a; if(vis(a))o.visible++;});
 if(!first) return o;
 var root=first.closest('nav,[role=navigation],aside,header')||first.parentElement;
 o.rootTag=root.tagName.toLowerCase(); o.rootCls=String(root.className||'');
 o.rootH=Math.round(root.getBoundingClientRect().height);
 var li=first.closest('li'); if(li) o.listStyle=getComputedStyle(li).listStyleType;
 var cls={};
 for(var e=first.parentElement;e&&e!==root;e=e.parentElement){
   for(var i=0;i<e.classList.length;i++)cls[e.classList[i]]=1;
   if(e.parentElement){for(var s=e.parentElement.firstElementChild;s;s=s.nextElementSibling){
     if(s!==e&&s.tagName!=='UL'&&s.tagName!=='OL'){for(var j=0;j<s.classList.length;j++)cls[s.classList[j]]=1;}}}
 }
 for(var i=0;i<first.classList.length;i++)cls[first.classList[i]]=1;
 o.classes=Object.keys(cls);
 var res=o.classes.map(function(c){return new RegExp('\\.'+c.replace(/[-]/g,'\\-')+'(?![\\w-])');});
 function walk(rules,theme){
   for(var i=0;i<rules.length;i++){var r=rules[i];
     if(r.cssRules&&!r.selectorText){walk(r.cssRules,theme);continue;}
     if(!r.selectorText)continue;
     for(var k=0;k<res.length;k++){if(res[k].test(r.selectorText)){if(theme)o.themeRules++;else o.inlineRules++;break;}}}
 }
 for(var i=0;i<document.styleSheets.length;i++){var sh=document.styleSheets[i], rules;
   try{rules=sh.cssRules}catch(e){continue}
   var theme=!!(sh.href&&sh.href.indexOf('/lazysite-assets/')>=0);
   walk(rules,theme);}
 return o;
})
"""

JS_FORM = r"""
(function(){
 var o={optRulesTheme:0, optRulesInline:0, anyFormRulesTheme:0, anyFormRulesInline:0, labels:0, rows:0, border:null, widthRatio:null, boxW:null, boxBorder:null};
 var reOpt=/\.form-option(s|-qty)?(?![\w-])/, reAny=/\.form-[a-z]/;
 function walk(rules,theme){
   for(var i=0;i<rules.length;i++){var r=rules[i];
     if(r.cssRules&&!r.selectorText){walk(r.cssRules,theme);continue;}
     if(!r.selectorText)continue;
     if(reOpt.test(r.selectorText)){if(theme)o.optRulesTheme++;else o.optRulesInline++;}
     if(reAny.test(r.selectorText)){if(theme)o.anyFormRulesTheme++;else o.anyFormRulesInline++;}}
 }
 for(var i=0;i<document.styleSheets.length;i++){var sh=document.styleSheets[i], rules;
   try{rules=sh.cssRules}catch(e){continue}
   walk(rules,!!(sh.href&&sh.href.indexOf('/lazysite-assets/')>=0));}
 var g=document.querySelector('.form-options');
 if(g){var ls=g.querySelectorAll('label.form-option'); o.labels=ls.length;
   var tops={};for(var i=0;i<ls.length;i++)tops[Math.round(ls[i].getBoundingClientRect().top)]=1;
   o.rows=Object.keys(tops).length;
   if(ls.length){var l=ls[0], cs=getComputedStyle(l), gw=g.getBoundingClientRect().width;
     o.border=parseFloat(cs.borderTopWidth)||0; o.widthRatio=gw?+(l.getBoundingClientRect().width/gw).toFixed(2):null;
     var b=l.querySelector('input'); if(b){var bs=getComputedStyle(b); o.boxW=Math.round(b.getBoundingClientRect().width); o.boxBorder=parseFloat(bs.borderTopWidth)||0;}}}
 return o;
})()
"""

JS_ICON = r"""
(async function(){
 var l=document.querySelector('link[rel~="icon"]'); if(!l) return {href:null};
 var h=l.getAttribute('href');
 try{var r=await fetch(h,{cache:'no-store'}); return {href:h,status:r.status,type:r.headers.get('content-type')||''};}
 catch(e){return {href:h,status:0,type:String(e)};}
})()
"""

def scheme(tab, dark):
    tab.cmd('Emulation.setEmulatedMedia', {'features': [{'name': 'prefers-color-scheme', 'value': 'dark' if dark else 'light'}]})
    time.sleep(0.12)

def size(tab, w):
    h = 900 if w >= 1000 else 844
    tab.cmd('Emulation.setDeviceMetricsOverride', {'width': w, 'height': h, 'deviceScaleFactor': 1, 'mobile': w < 600})

def shot(tab, name):
    try: tab.shot(os.path.join(SHOTS, name), full=False)
    except Exception as e: print('  shot failed', name, e)

tab = Tab(width=1280, height=900, port=PORT)
results = {'themes': {}, 'proof': {}}
t0 = time.time()
try:
    for L, T in themes:
        key = '%s/%s' % (L, T)
        r = results['themes'][key] = {'layout': L, 'theme': T, 'scroll': {}}
        for page, path in (('spec', '/s/%s/%s' % (L, T)), ('steps', '/f/%s/%s' % (L, T))):
            for w in (390, 1280):
                size(tab, w)
                scheme(tab, False)
                tab.go(BASE + path, settle=0.35)
                for dark in (False, True):
                    scheme(tab, dark)
                    tab.js('document.documentElement.setAttribute("data-theme", %s)' % ('"dark"' if dark else '"light"'))
                    time.sleep(0.08)
                    m = tab.js(JS_SCROLL)
                    sk = '%s-%d-%s' % (page, w, 'dark' if dark else 'light')
                    r['scroll'][sk] = m
                    tab.js('document.documentElement.removeAttribute("data-theme")')
                scheme(tab, False)
                if page == 'spec':
                    nav = tab.js('(%s)(%s)' % (JS_NAV, json.dumps(CHILD_HREFS)))
                    r['nav%d' % w] = nav
                    r['top%d' % w] = tab.js('(%s)(%s)' % (JS_NAV, json.dumps(TOP_HREFS)))
                    if w == 390:
                        # open the mobile menu where there is a toggle, then read the nav again
                        opened = tab.js('(function(){var b=document.querySelector("button[aria-expanded]");'
                                        'if(!b||!b.getBoundingClientRect().width)return false;b.click();return true;})()')
                        if opened:
                            time.sleep(0.3)
                            r['nav390open'] = tab.js('(%s)(%s)' % (JS_NAV, json.dumps(CHILD_HREFS)))
                        r['toggle390'] = bool(opened)
                    if w == 1280:
                        r['form'] = tab.js(JS_FORM)
                        r['icon'] = tab.js(JS_ICON)
                        r['title'] = tab.js('document.title')
                    shot(tab, '%s--%s--%d-light.png' % (L, T, w))
                    if w == 1280:
                        scheme(tab, True)
                        shot(tab, '%s--%s--%d-dark.png' % (L, T, w))
                        scheme(tab, False)
        print('%s done (%.0fs)' % (key, time.time() - t0), flush=True)
finally:
    tab.close()

# ---- the 24/08 filing's proof, per layout, over plain HTTP ---------------
def fetch(path):
    try:
        r = urllib.request.urlopen(BASE + path, timeout=30)
        return r.status, r.headers.get('content-type', ''), r.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get('content-type', ''), ''

def put_page(rel, layout, theme, title):
    p = os.path.join(DOC, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    pins = 'layout: %s\n' % layout + ('theme: %s\n' % theme if theme else '')
    open(p, 'w').write('---\ntitle: %s\n%s---\nA plain proof page with one paragraph.\n' % (title, pins))

TOP = [('Home', '/'), ('Specimen', '/s/default/default'), ('Form in steps', '/f/default/default'), ('Contact', '/contact')]
GROUPS = ['Discover', 'Configure', 'Develop']
CHILDREN = [('Authoring', '/docs/authoring'), ('All features', '/docs/features'), ('API and raw mode', '/docs/api'),
            ('Configuration', '/docs/configuration'), ('Reference', '/docs/reference'), ('Themes and layouts', '/docs/themes'),
            ('Installing', '/docs/install'), ('Contributing', '/docs/development')]

def anchors(html):
    return re.findall(r'<a\b([^>]*)>(.*?)</a>', html, re.S)

def has_link(html, label, url):
    for attrs, inner in anchors(html):
        m = re.search(r'href="([^"]*)"', attrs)
        if m and m.group(1) == url and label in re.sub(r'<[^>]+>', '', inner):
            return attrs
    return None

lay_first = {}
for L, T in themes:
    lay_first.setdefault(L, T)
for L, T in lay_first.items():
    pr = results['proof'][L] = {'theme': T}
    put_page('contact.md', L, T, 'Contact')
    s, _, html = fetch('/contact')
    pr['status'] = s
    if L == 'explorer' or 'rel="icon"' in html:
        pass
    missing = []
    for lab, url in TOP + CHILDREN:
        if not has_link(html, lab, url): missing.append(lab)
    for g in GROUPS:
        if g not in re.sub(r'<[^>]+>', ' ', html): missing.append(g)
    pr['missing'] = missing
    cur = has_link(html, 'Contact', '/contact')
    pr['active_top'] = bool(cur and re.search(r'active|aria-current', cur))
    put_page('docs/authoring.md', L, T, 'Authoring')
    s2, _, h2 = fetch('/docs/authoring')
    cur2 = has_link(h2, 'Authoring', '/docs/authoring')
    pr['active_child'] = bool(cur2 and re.search(r'active|aria-current', cur2))
    # a link that targets a fragment of the layout's own demo content
    frags = [m.group(1) for a, _ in anchors(html) for m in [re.search(r'href="(#[^"]*)"', a)] if m]
    pr['fragments'] = [f for f in frags if f != '#']
    ic = re.search(r'<link\b[^>]*rel="icon"[^>]*>', html)
    if ic:
        h = re.search(r'href="([^"]*)"', ic.group(0)).group(1)
        st, ct, _ = fetch(h)
        pr['icon'] = {'href': h, 'status': st, 'type': ct.split(';')[0]}
    else:
        pr['icon'] = {'href': None}
    # the no-theme edge: layout pinned, no theme resolves
    put_page('docs/authoring.md', L, 'no-such-theme', 'Authoring')
    s3, _, h3 = fetch('/docs/authoring')
    ic3 = re.search(r'<link\b[^>]*rel="icon"[^>]*>', h3)
    if ic3:
        h = re.search(r'href="([^"]*)"', ic3.group(0)).group(1)
        st, ct, _ = fetch(h)
        pr['icon_notheme'] = {'href': h, 'status': st, 'type': ct.split(';')[0]}
    else:
        pr['icon_notheme'] = {'href': None}
    print('proof %s done' % L, flush=True)
# a layout with no default_theme and no theme: the true unthemed edge (L-3)
ul = os.path.join(DOC, 'lazysite', 'layouts', 'unthemed')
os.makedirs(ul, exist_ok=True)
open(os.path.join(ul, 'layout.tt'), 'w').write(open(os.path.join(DOC, 'lazysite', 'layouts', 'default', 'layout.tt')).read())
put_page('docs/authoring.md', 'unthemed', None, 'Authoring')
_, _, hu = fetch('/docs/authoring')
icu = re.search(r'<link\b[^>]*rel="icon"[^>]*>', hu)
if icu:
    h = re.search(r'href="([^"]*)"', icu.group(0)).group(1)
    st, ct, _ = fetch(h)
    results['unthemed'] = {'href': h, 'status': st, 'type': ct.split(';')[0]}
else:
    results['unthemed'] = {'href': None}
import shutil
shutil.rmtree(ul, ignore_errors=True)
for rel in ('contact.md', 'docs/authoring.md'):
    try: os.remove(os.path.join(DOC, rel))
    except OSError: pass
try: os.rmdir(os.path.join(DOC, 'docs'))
except OSError: pass

json.dump(results, open(os.path.join(RIG, 'results.json'), 'w'), indent=1)
print('wrote results.json')
