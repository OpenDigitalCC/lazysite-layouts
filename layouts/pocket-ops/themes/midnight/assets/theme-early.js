/* Loaded in <head> before the stylesheets, without defer, so two things are
 * settled before the first paint: data-po-js on <html> (the stylesheet then
 * collapses the apps into the menu button on a narrow screen; without script
 * the apps row scrolls sideways instead), and a colour scheme the person chose
 * (pocket-ops.js keeps it under pocket-ops.theme). A file rather than an inline
 * script, so the page needs no inline code under the site's script policy. */
document.documentElement.setAttribute('data-po-js', '');
try { var m = localStorage.getItem('pocket-ops.theme'); if (m === 'light' || m === 'dark') document.documentElement.setAttribute('data-theme', m); } catch (e) { /* no storage: the device decides */ }
