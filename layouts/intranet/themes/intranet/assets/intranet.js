/* Intranet: the Menu button on a narrow screen. Marks the page as scripted
 * (so the section nav is hidden until asked for), then opens and closes it.
 * Without this file the nav is listed above the page and nothing is lost. */
(function () {
  var root = document.documentElement;
  root.classList.add('in-js');
  document.addEventListener('DOMContentLoaded', function () {
    var button = document.querySelector('[data-in-menu]');
    if (!button) return;
    function set(open) {
      root.classList.toggle('in-nav-open', open);
      button.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
    button.addEventListener('click', function () {
      set(!root.classList.contains('in-nav-open'));
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && root.classList.contains('in-nav-open')) {
        set(false);
        button.focus();
      }
    });
  });
})();
