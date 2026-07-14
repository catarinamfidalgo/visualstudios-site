/* Mobile navigation: toggle the collapsed nav with the hamburger button. */
(function () {
  "use strict";
  var header = document.querySelector(".site-header");
  var btn = document.querySelector(".nav-toggle");
  if (!header || !btn) return;
  var nav = header.querySelector(".nav");

  function set(open) {
    header.classList.toggle("nav-open", open);
    btn.setAttribute("aria-expanded", open ? "true" : "false");
    btn.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  }

  btn.addEventListener("click", function () {
    set(!header.classList.contains("nav-open"));
  });

  // Close after tapping a link, on Escape, or when resized back to desktop.
  if (nav) nav.addEventListener("click", function (e) {
    if (e.target.closest("a")) set(false);
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") set(false);
  });
  window.addEventListener("resize", function () {
    if (window.innerWidth > 760) set(false);
  });
})();
