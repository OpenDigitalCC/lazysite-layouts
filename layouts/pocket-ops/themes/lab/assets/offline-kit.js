/* Pocket Ops - working without a connection, on every page (design-system
 * installed-app.md "Offline and sync"; the ConnectionBanner pattern). The layout
 * loads this last in <body>; it needs pocket-ops.js and the Odoo helper
 * (lazysite's /assets/lazysite-odoo.js), and does nothing on a page without
 * them. The pages themselves are kept by lazysite's own worker (app_offline_pages
 * in lazysite.conf); this kit keeps what the pages READ.
 *
 * WHAT EVERY PAGE GETS, WITH NO CHANGE TO ITS APP
 *   PocketOps.read keeps its answers (as PocketOps._offlineRead, which
 *     pocket-ops.js chooses at call time). Online, each answer is kept on this
 *     device with the time (answers over 512 KB, such as PDFs, are not).
 *     Offline, the kept answer for the same binding and parameters comes back
 *     instead, marked r.kept = time; with none kept, an answer saying so. So a
 *     page that was opened once shows its last data with no connection.
 *   PocketOps.write needs a connection. Offline it answers "needs a connection,
 *     nothing was sent" at once; a connection lost mid-request answers that it
 *     is not known whether the change reached the server. Its submit button is
 *     dimmed while offline unless it is marked data-po-queues.
 *   The connection banner, in the layout's [data-po-banner], and the app's state
 *     in the footer ([data-po-app-status]).
 *
 * WHAT AN APP OPTS INTO: a change kept and sent later
 *   PocketOpsOffline.send({ key, binding, params, label })  saved on this device
 *     first, then sent, now or when the connection returns. ONLY for an
 *     operation that looks for the key before acting, so a send that was cut off
 *     and made again makes nothing twice. Each change records who made it, and
 *     is sent only while that person is signed in.
 *   PocketOpsOffline.queued(), retry(), forget(key), on(fn), isOffline(), busy(fn),
 *     install(name), waitingList(el, binding, describe).
 *   PocketOpsOffline.read(binding, params) -> { r, from: 'live'|'kept'|'none', at }.
 *
 * THE DATA ON THE DEVICE belongs to the person signed in: kept answers are
 * cleared when the server refuses the session (401), when a different person is
 * signed in, and on sign-out. Signing out with changes of one's own not yet sent
 * asks first, in the page; while anything is not on the server, the banner says
 * so on every page. Who is signed in comes from the Odoo helper (PocketOps.who):
 * a name only, and the session itself stays the server's. */
(function (root) {
  'use strict';
  var L = root.PocketOps;
  if (!L || root.PocketOpsOffline) return;
  var O = {}, raw = { read: L._read, write: L._write };
  var DBNAME = 'pocket-ops-offline', db = null, listeners = [], MAX_KEEP = 512 * 1024;
  var st = { offline: false, syncing: false, signin: false, update: false, oldest: null, ask: 0 };
  var busy = function () { return false; };

  /* ---- the store: kept answers and queued changes ---- */
  function open() {
    if (db) return db;
    db = new Promise(function (resolve, reject) {
      if (!root.indexedDB) return reject(new Error('no IndexedDB'));
      var q = root.indexedDB.open(DBNAME, 1);
      q.onupgradeneeded = function () {
        var d = q.result;
        if (!d.objectStoreNames.contains('kept')) d.createObjectStore('kept', { keyPath: 'name' });
        if (!d.objectStoreNames.contains('queue')) d.createObjectStore('queue', { keyPath: 'key' });
      };
      q.onsuccess = function () { resolve(q.result); };
      q.onerror = function () { reject(q.error); };
    });
    return db;
  }
  function tx(store, mode, fn) {
    return open().then(function (d) {
      return new Promise(function (resolve, reject) {
        var t = d.transaction(store, mode), out = fn(t.objectStore(store));
        t.oncomplete = function () { resolve(out && out.result !== undefined ? out.result : undefined); };
        t.onerror = function () { reject(t.error); };
      });
    });
  }
  function stable(v) {
    if (v === null || typeof v !== 'object') return JSON.stringify(v);
    return '{' + Object.keys(v).sort().map(function (k) { return JSON.stringify(k) + ':' + stable(v[k]); }).join(',') + '}';
  }
  function keyOf(binding, params) { return 'r|' + binding + '|' + stable(params || {}); }
  function clearKept() { return tx('kept', 'readwrite', function (s) { s.clear(); }).catch(function () {}); }

  function netFail(r) { return !r || r.status === 0 || r.status === 502 || r.status === 503 || r.status === 504; }
  function setOnline(yes) { var was = st.offline; st.offline = !yes; if (was !== st.offline) render(); if (yes && was) O.flush(); }
  function emit(ev) { listeners.forEach(function (fn) { try { fn(ev); } catch (e) { /* a listener's fault stays its own */ } }); render(); }

  /* ---- who is signed in: the owner of kept answers and of queued changes ---- */
  function current() { return L.who().then(function (me) { return me ? { login: me.name, name: me.name } : null; }, function () { return null; }); }
  /* Kept answers belong to one person: when the person signed in is not the one
   * who kept them, they go. Checked once per page, when the kit starts. */
  function ownerCheck() {
    return current().then(function (who) {
      if (!who) return;
      return tx('kept', 'readonly', function (s) { return s.get('__owner'); }).then(function (o) {
        var gone = o && o.login !== who.login ? clearKept() : null;
        return Promise.resolve(gone).then(function () {
          return tx('kept', 'readwrite', function (s) { s.put({ name: '__owner', login: who.login }); });
        });
      });
    }).catch(function () {});
  }

  /* ---- every read keeps its answer ---- */
  L._offlineRead = function (binding, params, opts) {
    var name = keyOf(binding, params);
    return raw.read(binding, params, opts).then(function (r) {
      if (r && r.data && r.data.kind === 'unavailable') return r;
      if (netFail(r)) throw new Error('offline');
      setOnline(true);
      if (r.status === 401) { clearKept(); return r; }
      if (r.data && r.data.ok) {
        var text = JSON.stringify(r.data);
        if (text.length <= MAX_KEEP)
          tx('kept', 'readwrite', function (s) { s.put({ name: name, r: { status: r.status, data: r.data }, at: Date.now() }); }).catch(function () {});
      }
      return r;
    }).catch(function () {
      setOnline(false);
      return tx('kept', 'readonly', function (s) { return s.get(name); }).then(function (k) {
        if (k && k.r) {
          if (!st.oldest || k.at < st.oldest) { st.oldest = k.at; render(); }
          return { status: k.r.status, data: k.r.data, kept: k.at };
        }
        return { status: 0, data: { ok: 0, kind: 'offline', error: 'There is no connection, and this has not been opened on this device before.' } };
      }, function () {
        return { status: 0, data: { ok: 0, kind: 'offline', error: 'There is no connection.' } };
      });
    });
  };
  O.read = function (binding, params) {
    return L.read(binding, params).then(function (r) {
      if (r.kept) return { r: r, from: 'kept', at: r.kept };
      if (r.data && r.data.kind === 'offline') return { r: r, from: 'none', at: null };
      return { r: r, from: 'live', at: Date.now() };
    });
  };

  /* ---- a write needs a connection, unless it is a queued change being sent ---- */
  var NEEDS = 'This needs a connection. Nothing was sent; try again when you are back online.';
  var UNKNOWN = 'The connection dropped before the server answered, so it is not known whether this was received. Check before trying again.';
  L._offlineWrite = function (binding, params, opts) {
    if (opts && opts.queued) return raw.write(binding, params, opts);
    if (st.offline) return Promise.resolve({ status: 0, data: { ok: 0, kind: 'offline', error: NEEDS } });
    return raw.write(binding, params, opts).then(function (r) {
      if (r && r.data && r.data.kind === 'unavailable') return r;
      if (netFail(r)) { setOnline(false); return { status: 0, data: { ok: 0, kind: 'offline', error: UNKNOWN } }; }
      setOnline(true);
      if (r.status === 401) clearKept();
      return r;
    }, function () { setOnline(false); return { status: 0, data: { ok: 0, kind: 'offline', error: UNKNOWN } }; });
  };

  /* ---- changes kept on the device and sent later (opt-in per action) ---- */
  O.queued = function () {
    return tx('queue', 'readonly', function (s) { return s.getAll(); })
      .then(function (a) { return (a || []).sort(function (x, y) { return x.at - y.at; }); }, function () { return []; });
  };
  function mine(a, who) { return a.filter(function (i) { return !i.who || (who && i.who.login === who.login); }); }
  O.send = function (item) {
    return current().then(function (who) {
      var it = { key: item.key, binding: item.binding, params: item.params, label: item.label || '', at: Date.now(),
        state: 'pending', error: '', who: who };
      return tx('queue', 'readwrite', function (s) { s.put(it); }).then(function () {
        emit({ event: 'change', item: it }); O.flush(); return it;
      });
    });
  };
  O.forget = function (key) { return tx('queue', 'readwrite', function (s) { s.delete(key); }).then(function () { emit({ event: 'change' }); }); };
  O.retry = function () {
    return O.queued().then(function (a) {
      return Promise.all(a.filter(function (i) { return i.state === 'refused'; }).map(function (i) {
        i.state = 'pending'; i.error = '';
        return tx('queue', 'readwrite', function (s) { s.put(i); });
      }));
    }).then(function () { st.signin = false; emit({ event: 'change' }); return O.flush(); });
  };
  var flushing = null;
  O.flush = function () {
    if (flushing) return flushing;
    flushing = Promise.all([O.queued(), current()]).then(function (got) {
      var who = got[1], todo = mine(got[0], who).filter(function (i) { return i.state === 'pending'; });
      if (!todo.length) return;
      st.syncing = true; render();
      return todo.reduce(function (p, item) {
        return p.then(function (go) {
          if (!go) return false;
          return raw.write(item.binding, item.params, { prompt: false, queued: true }).then(function (r) {
            if (netFail(r)) { setOnline(false); return false; }
            setOnline(true);
            if (r.status === 401) { st.signin = true; return false; }
            if (r.status === 429) return false;   /* the site's rate cap: try again later */
            var res = r.data && r.data.result;
            if (r.data && r.data.ok && !(res && res.counts && res.counts.held)) {
              return tx('queue', 'readwrite', function (s) { s.delete(item.key); }).then(function () { emit({ event: 'sent', item: item, r: r }); return true; });
            }
            item.state = 'refused';
            var held = res && (res.changes || []).filter(function (c) { return c.outcome === 'held' && c.reason; }).map(function (c) { return c.reason; });
            item.error = (r.data && r.data.ok) ? 'The server did not take it: ' + (held && held.length ? held.join('; ') : 'a value was refused') + '.' : L.err(r);
            return tx('queue', 'readwrite', function (s) { s.put(item); }).then(function () { emit({ event: 'refused', item: item, r: r }); return true; });
          }, function () { setOnline(false); return false; });
        });
      }, Promise.resolve(true));
    }).then(function () { st.syncing = false; flushing = null; render(); },
            function () { st.syncing = false; flushing = null; render(); });
    return flushing;
  };
  O.on = function (fn) { listeners.push(fn); };

  /* A plain "Not sent yet" list for an app's queued changes of one binding:
   * each with its label, whether it is waiting or why it was refused, and
   * Discard. describe(item) may return a fuller line than the label. */
  O.waitingList = function (el, binding, describe) {
    if (!el) return;
    function draw() {
      Promise.all([O.queued(), current()]).then(function (got) {
        var a = mine(got[0], got[1]).filter(function (i) { return i.binding === binding; });
        el.textContent = ''; el.hidden = !a.length;
        if (!a.length) return;
        el.appendChild(L.el('h3', {}, 'Not sent yet'));
        var ul = L.el('ul', { 'class': 'po-waiting' });
        a.forEach(function (i) {
          var li = L.el('li', { 'class': 'po-wait' + (i.state === 'refused' ? ' refused' : '') });
          li.appendChild(L.el('div', { 'class': 'po-wait-head' }, (describe && describe(i)) || i.label));
          li.appendChild(L.el('div', { 'class': 'po-wait-sub' }, i.state === 'refused' ? 'Not sent: ' + i.error : 'Saved on this device, waiting to send'));
          if (i.state === 'refused') {
            var d = L.el('button', { type: 'button', 'class': 'po-quiet' }, 'Discard');
            d.addEventListener('click', function () { O.forget(i.key); });
            var row = L.el('div', { 'class': 'po-wait-actions' }); row.appendChild(d); li.appendChild(row);
          }
          ul.appendChild(li);
        });
        el.appendChild(ul);
      });
    }
    O.on(draw); draw();
  };
  O.isOffline = function () { return st.offline; };
  O.busy = function (fn) { busy = fn; };
  O.banner = function (el, opts) { if (opts && opts.busy) busy = opts.busy; render(); };   /* the layout's slot is used */

  /* ---- signing out: kept data goes; one's own unsent changes are asked about first ---- */
  function signOut() {
    return clearKept().then(function () {
      st.ask = 0;
      var A = root.LazysiteOdoo;
      if (A && A.signOut) return A.signOut().then(function () { root.location.reload(); }, function () { root.location.reload(); });
      root.location.reload();
    });
  }
  function dropMineAndSignOut() {
    return Promise.all([O.queued(), current()]).then(function (got) {
      return Promise.all(mine(got[0], got[1]).map(function (i) { return tx('queue', 'readwrite', function (s) { s.delete(i.key); }); }));
    }).then(signOut);
  }
  document.addEventListener('click', function (ev) {
    var b = ev.target.closest && ev.target.closest('[data-ls-odoo-signout]');
    if (!b) return;
    ev.preventDefault(); ev.stopImmediatePropagation();
    Promise.all([O.queued(), current()]).then(function (got) {
      var n = mine(got[0], got[1]).length;
      if (!n) return signOut();
      st.ask = n; render();
      var slot = document.querySelector('[data-po-banner]'); if (slot) slot.scrollIntoView({ block: 'nearest' });
    });
  }, true);

  /* ---- the banner: one line, in the layout's slot ---- */
  function when(at) {
    if (!at) return '';
    var d = new Date(at), today = new Date();
    var t = ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2);
    return d.toDateString() === today.toDateString() ? 'today at ' + t
      : ('0' + d.getDate()).slice(-2) + '/' + ('0' + (d.getMonth() + 1)).slice(-2) + '/' + d.getFullYear() + ' at ' + t;
  }
  function plural(n, w) { return n + ' ' + w + (n === 1 ? '' : 's'); }
  function render() {
    document.documentElement.setAttribute('data-po-offline', st.offline ? '1' : '0');
    var el = document.querySelector('[data-po-banner]');
    if (!el) return;
    Promise.all([O.queued(), current()]).then(function (got) {
      var all = got[0], who = got[1], my = mine(all, who), others = all.length - my.length;
      var pend = my.filter(function (i) { return i.state === 'pending'; }).length;
      var bad = my.filter(function (i) { return i.state === 'refused'; }).length;
      var tone = null, text = '', acts = [];
      if (st.ask) {
        tone = 'danger';
        text = plural(st.ask, 'change') + ' on this device ' + (st.ask === 1 ? 'is' : 'are') + ' not sent yet. Signing out deletes ' + (st.ask === 1 ? 'it' : 'them') + '.';
        acts = [['Stay signed in', function () { st.ask = 0; render(); }], ['Delete and sign out', dropMineAndSignOut]];
      } else if (bad) { tone = 'danger'; text = plural(bad, 'change') + ' couldn’t be sent.'; acts = [['Try again', O.retry]]; }
      else if (st.offline) {
        tone = 'warning';
        text = 'You’re offline. ' + (pend ? plural(pend, 'change') + ' saved on this device, not sent yet.' : 'Changes that can wait are saved on this device and sent when you reconnect.')
          + (st.oldest ? ' Showing what was last read ' + when(st.oldest) + '.' : '');
      }
      else if (st.signin && pend) { tone = 'info'; text = plural(pend, 'change') + ' not sent yet. Sign in again to send ' + (pend === 1 ? 'it' : 'them') + '.'; }
      else if (st.syncing && pend) { tone = 'info'; text = 'Sending ' + plural(pend, 'change') + '…'; }
      else if (pend) { tone = 'info'; text = plural(pend, 'change') + ' saved on this device, not sent yet.'; }
      else if (st.update && !busy()) { tone = 'info'; text = 'A new version of the app is ready.'; acts = [['Reload', O.reloadToUpdate]]; }
      if (!tone && others) {
        var names = all.filter(function (i) { return my.indexOf(i) < 0; }).map(function (i) { return i.who && i.who.name; }).filter(Boolean);
        tone = 'info'; text = plural(others, 'change') + ' saved on this device by ' + (names[0] || 'someone else') + ' ' + (others === 1 ? 'is' : 'are') + ' waiting for them to sign in.';
      }
      el.textContent = ''; el.hidden = !tone;
      if (!tone) return;
      el.className = 'po-banner po-banner-' + tone;
      el.setAttribute('role', tone === 'danger' ? 'alert' : 'status');
      el.appendChild(L.el('span', {}, text));
      if (acts.length) {
        var box = L.el('span', { 'class': 'po-banner-acts' });
        acts.forEach(function (a) { var b = L.el('button', { type: 'button', 'class': 'po-banner-action' }, a[0]); b.addEventListener('click', function () { a[1](); }); box.appendChild(b); });
        el.appendChild(box);
      }
    });
  }
  O.render = render;

  /* ---- a newer version of the app (service worker) ----
   * lazysite's own registration script (lazysite-app.js) holds a new worker back
   * when lazysite.conf says `app_update: wait`, tells the page with a
   * `lazysite-app-update` event on window, and reloads once when the page calls
   * detail.apply(). The banner's "Reload" does that. With `app_update: now`
   * (the default) a new version takes over at once and the banner never shows. */
  var applyUpdate = null;
  function updateReady(apply) { applyUpdate = apply; st.update = true; render(); }
  O.reloadToUpdate = function () { if (applyUpdate) applyUpdate(); else root.location.reload(); };
  root.addEventListener('lazysite-app-update', function (e) { if (e && e.detail && e.detail.apply) updateReady(e.detail.apply); });
  if (root.lazysiteApp && root.lazysiteApp.apply) updateReady(root.lazysiteApp.apply);

  /* ---- the app's state in the footer (installed, can install, works offline, needs https) ---- */
  var deferred = null, installName = 'the app', installed = false;
  function standalone() { return (root.matchMedia && root.matchMedia('(display-mode: standalone)').matches) || root.navigator.standalone === true; }
  function drawInstall() {
    var box = document.querySelector('[data-po-app-status]');
    if (!box || !document.querySelector('link[rel="manifest"]')) return;
    var sum = box.querySelector('summary'), pop = box.querySelector('.po-app-pop'), ua = root.navigator.userAgent || '';
    var ok, line, title, body = [], button = null;
    if (standalone() || installed) {
      ok = true; line = 'Installed app'; title = 'Open from your home screen or apps; it works without a connection.';
      body.push(installed && !standalone() ? 'Installed. Open it from your home screen or apps.' : 'You are using the installed app. It keeps working without a connection.');
    } else if (!root.isSecureContext) {
      ok = false; line = 'App needs https'; title = 'This plain-http address cannot install the app or keep it for offline use.';
      body.push('Installing, and keeping the app for use without a connection, needs a secure address (https). On ' + root.location.host + ' the browser offers neither.');
      body.push('For testing: in Firefox, add ' + root.location.hostname + ' (the address alone, no port or range) to dom.securecontext.allowlist in about:config. In Chrome, add ' + root.location.origin + ' at chrome://flags/#unsafely-treat-insecure-origin-as-secure.');
    } else if (deferred) {
      ok = true; line = 'Can be installed'; title = 'Install it to open from your home screen, in its own window, and use it without a connection.';
      body.push('It opens from your home screen in its own window and keeps working without a connection.');
      button = L.el('button', { type: 'button', 'class': 'po-primary' }, 'Install ' + installName);
      button.addEventListener('click', function () { var d = deferred; deferred = null; d.prompt(); (d.userChoice || Promise.resolve({})).then(function () { drawInstall(); }); });
    } else {
      ok = true; line = 'Works offline'; title = 'Pages opened here keep working without a connection.';
      body.push('Pages opened here keep working without a connection: they show what was last read, and changes that can wait are sent when it comes back.');
      if (/iPhone|iPad|iPod/.test(ua)) body.push('To install it on iPhone or iPad: tap Share, then Add to Home Screen.');
      else if (/Firefox/.test(ua) && /Android/.test(ua)) body.push('To install it in Firefox: open the menu, then Install (or Add to Home screen).');
      else if (/Firefox/.test(ua)) body.push('Firefox on a computer does not install web apps; keep it open in a tab.');
      else body.push('To install it, open the browser menu and choose Install app (or Add to Home screen). If it is not there yet, use the page for a moment and look again.');
    }
    box.hidden = false; box.className = 'po-app-status ' + (ok ? 'ok' : 'no');
    sum.textContent = '';
    sum.appendChild(L.el('span', { 'class': 'po-app-mark', 'aria-hidden': 'true' }, ok ? '✓' : '✗'));
    sum.appendChild(document.createTextNode(' ' + line));
    sum.setAttribute('title', title);
    pop.textContent = '';
    body.forEach(function (s) { pop.appendChild(L.el('p', {}, s)); });
    if (button) pop.appendChild(button);
  }
  O.install = function (name) { if (name) installName = name; drawInstall(); };
  root.addEventListener('beforeinstallprompt', function (e) { e.preventDefault(); deferred = e; drawInstall(); });
  root.addEventListener('appinstalled', function () { deferred = null; installed = true; drawInstall(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { var b = document.querySelector('[data-po-app-status][open]'); if (b) b.open = false; } });
  document.addEventListener('click', function (e) { var b = document.querySelector('[data-po-app-status][open]'); if (b && !b.contains(e.target)) b.open = false; });

  /* ---- when to send: now, on reconnect, on return to the app, every 30 s while waiting ---- */
  root.addEventListener('online', function () { O.flush(); });
  root.addEventListener('offline', function () { setOnline(false); });
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'visible') O.flush(); });
  root.setInterval(function () { O.queued().then(function (a) { if (a.some(function (i) { return i.state === 'pending'; })) O.flush(); }); }, 30000);

  root.PocketOpsOffline = O;
  function start() {
    if (root.navigator && root.navigator.onLine === false) st.offline = true;
    ownerCheck(); drawInstall(); render(); O.flush();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})(window);
