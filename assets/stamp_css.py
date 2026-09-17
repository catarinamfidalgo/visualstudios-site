#!/usr/bin/env python3
"""Stamp the stylesheet link with a hash of its contents.

Browsers cache assets/site.css aggressively. Without a changing query the
stylesheet stays stale even when the page itself is reloaded — which is how the
hero background appeared to vanish. Run after any CSS change.
"""
import hashlib, re, pathlib

# Stamp the hero image with a hash of its own bytes first: the filename never
# changes, so without this the browser keeps showing a previous render.
img = pathlib.Path("assets/img/hero-timeline.jpg")
if img.exists():
    ih = hashlib.sha1(img.read_bytes()).hexdigest()[:8]
    css = pathlib.Path("assets/site.css")
    t = css.read_text(encoding="utf-8")
    t2 = re.sub(r"url\('img/hero-timeline\.jpg(\?v=[0-9a-f]+)?'\)",
                "url('img/hero-timeline.jpg?v=%s')" % ih, t)
    if t2 != t:
        css.write_text(t2, encoding="utf-8")
        print("stamped hero-timeline.jpg?v=%s" % ih)

h = hashlib.sha1(open("assets/site.css", "rb").read()).hexdigest()[:8]
changed = []
for p in list(pathlib.Path(".").rglob("*.html")) + [pathlib.Path("assets/build_blog.py")]:
    if not p.exists():
        continue
    s = p.read_text(encoding="utf-8")
    # Replace the entire existing query string, including older human-readable
    # stamps such as ?v=hero3. Matching only hexadecimal hashes left a second
    # query marker behind (for example ?v=c301a1ee?v=hero3).
    new = re.sub(r'(site\.css)(?:\?[^"\'\s>]*)?', r'\1?v=' + h, s)
    if new != s:
        p.write_text(new, encoding="utf-8")
        changed.append(str(p))
print(f"stamped site.css?v={h} in {len(changed)} file(s)")
for c in changed:
    print("  ", c)
