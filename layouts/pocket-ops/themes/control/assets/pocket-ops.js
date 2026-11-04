/* Pocket Ops - the small script the layout loads on every page, after the
 * header and before the page's own content. It adds:
 *   PocketOps.themeSet()   light, dark or auto, from [data-po-theme] buttons
 *   the menu button        [data-po-menu-toggle], on a narrow screen
 *   the signed-in state    data-po-signed-in="1|0" on <html>, which the theme's
 *                          sheet reads to show the signed-out notice and to hide
 *                          a .po-app block from a visitor who is not signed in
 *   PocketOps.read / PocketOps.write   the Odoo helper's calls
 *                          (/assets/lazysite-odoo.js, loaded by lazysite when
 *                          the Odoo extension is on), TIMED: every call is
 *                          recorded with its binding, status and milliseconds
 *   the timing line        #po-timing, if the site's pages carry one
 *   stacked tables         a table.po-stack labels its cells for narrow screens
 * window.pocketOpsTimings keeps every timing of this page view, for browser tests.
 * Everything shown from a server answer is set as text, never as HTML. A page
 * on a site without the Odoo extension gets the scheme switch, the menu, the
 * signed-in state and the stacked tables, and nothing else is called. */
(function (root) {
  'use strict';
  var PocketOps = {};
  var T = root.pocketOpsTimings = [];

  function api() {
    return new Promise(function (resolve) {
      (function wait(n) {
        if (root.LazysiteOdoo) return resolve(root.LazysiteOdoo);
        if (n > 200) return resolve(null);
        setTimeout(function () { wait(n + 1); }, 25);
      })(0);
    });
  }
  var NO_HELPER = { status: 0, data: { ok: 0, kind: 'unavailable', error: 'The Odoo helper is not on this page.' } };

  function timed(kind, binding, fn) {
    var t0 = performance.now();
    return fn().then(function (r) {
      var ms = Math.round(performance.now() - t0);
      T.push({ kind: kind, binding: binding, status: r.status, ok: !!(r.data && r.data.ok), ms: ms, at: Date.now() });
      if (r.status === 401) { lastKnown(null); setSignedIn(false); }
      PocketOps.showTiming();
      return r;
    });
  }

  /* PocketOps._read / _write are the calls themselves; PocketOps.read / .write
   * choose, at call time, the offline kit's versions (PocketOps._offlineRead /
   * _offlineWrite, set by offline-kit.js, which keep answers and know when there
   * is no connection) when the kit is on the page. The choice is made after the
   * helper has loaded - lazysite's helper loads deferred, after the page and the
   * kit - so an app that reads at once still goes through the kit.
   * A read never opens the sign-in dialog by itself: a page that needs a sign-in
   * says so once (the layout's notice) and the header's sign-in is the one way
   * in. A write still asks, since the person is in the middle of something and
   * the helper retries it once they are signed in. */
  PocketOps._read = function (binding, params, opts) {
    opts = Object.assign({ prompt: false }, opts || {});
    return api().then(function (A) {
      if (!A) return NO_HELPER;
      return timed('read', binding, function () { return A.read(binding, params, opts); });
    });
  };
  PocketOps._write = function (binding, params, opts) {
    return api().then(function (A) {
      if (!A) return NO_HELPER;
      return timed('write', binding, function () { return A.write(binding, params, opts); });
    });
  };
  PocketOps.read = function (binding, params, opts) {
    return api().then(function () { return (PocketOps._offlineRead || PocketOps._read)(binding, params, opts); });
  };
  PocketOps.write = function (binding, params, opts) {
    return api().then(function () { return (PocketOps._offlineWrite || PocketOps._write)(binding, params, opts); });
  };
  PocketOps.rows = function (r) { return (r && r.data && r.data.report && r.data.report.rows) || []; };
  PocketOps.err = function (r) {
    if (!r) return 'no answer';
    if (r.status === 401) return 'Sign in to see this.';
    return (r.data && (r.data.error || r.data.kind)) || ('HTTP ' + r.status);
  };

  PocketOps.el = function (tag, attrs, text) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) { e.setAttribute(k, attrs[k]); });
    if (text !== undefined && text !== null) e.textContent = String(text);
    return e;
  };
  PocketOps.q = function (name) { return new URLSearchParams(root.location.search).get(name); };

  PocketOps.showTiming = function () {
    var box = document.getElementById('po-timing');
    if (!box || !T.length) return;
    var last = T[T.length - 1];
    var ms = T.map(function (t) { return t.ms; }).sort(function (a, b) { return a - b; });
    var med = ms[Math.floor((ms.length - 1) / 2)];
    box.textContent = 'Via lazysite: last ' + last.binding + ' ' + last.ms + ' ms' +
      ' | this page ' + T.length + ' call' + (T.length > 1 ? 's' : '') + ', median ' + med + ' ms, slowest ' + ms[ms.length - 1] + ' ms';
  };

  /* Who is signed in. PocketOps.who() resolves { name } or null. With the Odoo
   * helper it asks the helper (no call to Odoo: the name comes with the token
   * fetch); without it, there is no name to give, only the site's own session
   * marker (the lzs_session cookie lazysite's sign-in sets, which a script can
   * see but which is not proof: the server decides what a person may do). */
  /* The last name this device knew, for when there is no connection to ask: an
   * installed app opened offline keeps the changes it holds as the person's own
   * instead of calling them someone else's. Only the display name is kept; the
   * session itself is the server's, and the first answer from the server puts
   * things right. Forgotten on sign-out and on a 401. */
  var LAST_KEY = 'pocket-ops.me-last';
  function lastKnown(name) {
    try {
      if (name === undefined) return root.localStorage.getItem(LAST_KEY) || '';
      if (name) root.localStorage.setItem(LAST_KEY, name); else root.localStorage.removeItem(LAST_KEY);
    } catch (e) { return ''; }
    return '';
  }
  function offlineWho() {
    var n = root.navigator && root.navigator.onLine === false ? lastKnown() : '';
    return n ? { name: n, offline: true } : null;
  }
  PocketOps.who = function () {
    return api().then(function (A) {
      if (!A || !A.who) return null;
      return A.who().then(function (id) {
        if (id && id.name) { lastKnown(id.name); return { name: id.name }; }
        var off = offlineWho();
        if (!off) lastKnown(null);
        return off;
      }, offlineWho);
    });
  };
  function setSignedIn(yes) {
    document.documentElement.setAttribute('data-po-signed-in', yes ? '1' : '0');
  }
  function sessionMarker() { return /(?:^|;\s*)lzs_session=/.test(document.cookie || ''); }
  function readSignedIn() {
    var odooSite = document.querySelector('[data-ls-odoo-banner], [data-ls-odoo-signin]');
    if (!odooSite) return setSignedIn(sessionMarker());
    PocketOps.who().then(function (me) { setSignedIn(!!me); });
  }
  PocketOps.signedIn = readSignedIn;
  /* Before the helper's own sign-out handler (capture), so the name goes. */
  document.addEventListener('click', function (ev) {
    if (ev.target.closest && ev.target.closest('[data-ls-odoo-signout]')) lastKnown(null);
  }, true);

  /* The helper's sign-in dialog labels its boxes for screen readers only; give
   * them visible placeholders too, whenever it opens. */
  if (root.MutationObserver) {
    new MutationObserver(function () {
      var box = document.querySelector('[data-ls-odoo-prompt]');
      if (!box) return;
      box.querySelectorAll('input[aria-label]:not([placeholder])').forEach(function (i) {
        i.setAttribute('placeholder', i.getAttribute('aria-label').replace(/^Odoo /, '').replace(/^./, function (c) { return c.toUpperCase(); }));
      });
    }).observe(document.documentElement, { childList: true, subtree: true });
  }

  /* DataTable, stacked variant: a table with class po-stack becomes one card
   * per row on a narrow screen (patterns.css). Each cell is labelled from its
   * column's heading here, whenever an app (re)draws the rows, so the apps'
   * row-building code does not change. A cell that has its own data-label
   * keeps it. */
  function labelStack(t) {
    var heads = t.querySelectorAll('thead th');
    if (!heads.length) return;
    t.querySelectorAll('tbody tr').forEach(function (tr) {
      var i = 0;
      Array.prototype.forEach.call(tr.children, function (td) {
        var h = heads[i];
        if (h && td.tagName === 'TD' && !td.hasAttribute('data-label')) td.setAttribute('data-label', h.textContent.trim());
        i += parseInt(td.getAttribute('colspan') || '1', 10);
      });
    });
  }
  PocketOps.labelStacks = function () { document.querySelectorAll('table.po-stack').forEach(labelStack); };
  if (root.MutationObserver) {
    new MutationObserver(function (muts) {
      for (var k = 0; k < muts.length; k++) {
        var t = muts[k].target.closest && muts[k].target.closest('table.po-stack');
        if (t) labelStack(t);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });
  }

  /* The menu button: on a narrow screen the apps open in a panel under the
   * header. The button carries aria-expanded and aria-controls (the layout);
   * Escape closes the panel and returns focus to the button. */
  function menuSet(btn, open) {
    var top = btn.closest('.po-top');
    if (!top) return;
    if (open) top.setAttribute('data-po-menu', 'open'); else top.removeAttribute('data-po-menu');
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  document.addEventListener('click', function (ev) {
    var b = ev.target.closest && ev.target.closest('[data-po-menu-toggle]');
    if (b) { ev.preventDefault(); menuSet(b, b.getAttribute('aria-expanded') !== 'true'); }
  });
  document.addEventListener('keydown', function (ev) {
    if (ev.key !== 'Escape') return;
    var b = document.querySelector('[data-po-menu-toggle][aria-expanded="true"]');
    if (b) { menuSet(b, false); b.focus(); }
  });

  /* Light or dark. 'auto' follows the device; 'light' or 'dark' is the
   * person's choice, kept in this browser (localStorage) and set as
   * <html data-theme>, which the theme's main.css reads. A button with
   * [data-po-theme] steps auto -> light -> dark -> auto. */
  var THEME_KEY = 'pocket-ops.theme', THEMES = ['auto', 'light', 'dark'];
  var THEME_NAMES = { auto: 'Auto', light: 'Light', dark: 'Dark' };

  PocketOps.themeValid = function (mode) { return THEMES.indexOf(mode) >= 0; };
  PocketOps.themeNext = function (mode) {
    var i = THEMES.indexOf(mode);
    return THEMES[(i + 1) % THEMES.length];
  };
  PocketOps.themeLabel = function (mode) {
    return 'Colour scheme: ' + THEME_NAMES[mode] + (mode === 'auto' ? ' (follows this device)' : '') + '. Change';
  };
  PocketOps.themeGet = function () {
    try {
      var m = root.localStorage.getItem(THEME_KEY);
      return PocketOps.themeValid(m) ? m : 'auto';
    } catch (e) { return 'auto'; }
  };
  PocketOps.themeApply = function (mode) {
    var html = document.documentElement;
    if (mode === 'auto') html.removeAttribute('data-theme');
    else html.setAttribute('data-theme', mode);
    var btns = document.querySelectorAll('[data-po-theme]');
    for (var i = 0; i < btns.length; i++) {
      btns[i].textContent = THEME_NAMES[mode];
      btns[i].setAttribute('aria-label', PocketOps.themeLabel(mode));
    }
    themeBar(mode);
  };
  PocketOps.themeSet = function (mode) {
    if (!PocketOps.themeValid(mode)) mode = 'auto';
    try {
      if (mode === 'auto') root.localStorage.removeItem(THEME_KEY);
      else root.localStorage.setItem(THEME_KEY, mode);
    } catch (e) { /* no storage: the choice lasts for this page only */ }
    PocketOps.themeApply(mode);
    return mode;
  };

  /* An installed app's system bar follows <meta name="theme-color">; when the
   * person forces a scheme, point every such tag at the forced top-bar colour,
   * and put the originals back for 'auto'. */
  function themeBar(mode) {
    var metas = document.querySelectorAll('meta[name="theme-color"]');
    if (!metas.length || !root.getComputedStyle) return;
    var surface = root.getComputedStyle(document.documentElement).getPropertyValue('--surface').trim();
    for (var i = 0; i < metas.length; i++) {
      var m = metas[i];
      if (!m.hasAttribute('data-po-original')) m.setAttribute('data-po-original', m.getAttribute('content') || '');
      m.setAttribute('content', mode === 'auto' || !surface ? m.getAttribute('data-po-original') : surface);
    }
  }

  document.addEventListener('click', function (ev) {
    var b = ev.target.closest && ev.target.closest('[data-po-theme]');
    if (b) { ev.preventDefault(); PocketOps.themeSet(PocketOps.themeNext(PocketOps.themeGet())); }
  });
  PocketOps.themeApply(PocketOps.themeGet());

  root.PocketOps = PocketOps;
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', readSignedIn); else readSignedIn();
})(window);
