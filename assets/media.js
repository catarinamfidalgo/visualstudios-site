/* Lazy, viewport-aware autoplay for the hotlinked CDN videos.
   Mirrors Carbonmade's "lazy" behaviour: muted autoplay/loop for clips in view,
   pause when out of view, and respect prefers-reduced-motion. */
(function () {
  "use strict";
  var reduce = window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce) document.body.classList.add("reduce-motion");

  var videos = Array.prototype.slice.call(document.querySelectorAll("video[data-src]"));

  function load(v) {
    if (!v.getAttribute("src")) v.setAttribute("src", v.getAttribute("data-src"));
  }
  function play(v) {
    load(v);
    var p = v.play();
    if (p && p.catch) p.catch(function () {});
    var card = v.closest && v.closest(".reel-card");
    if (card) card.classList.add("playing");
  }
  function pause(v) {
    if (!v.paused) v.pause();
  }

  if (reduce) {
    // No autoplay. Tap a reel to play/pause it; heroes stay on their poster.
    document.querySelectorAll(".reel-card").forEach(function (card) {
      card.addEventListener("click", function () {
        var v = card.querySelector("video");
        if (!v) return;
        if (v.paused) { play(v); } else { pause(v); card.classList.remove("playing"); }
      });
    });
    return;
  }

  if (!("IntersectionObserver" in window)) {
    videos.forEach(play);
    return;
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) play(e.target);
      else pause(e.target);
    });
  }, { rootMargin: "200px 0px", threshold: 0.1 });

  videos.forEach(function (v) { io.observe(v); });
})();
