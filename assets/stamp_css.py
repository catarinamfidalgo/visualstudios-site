#!/usr/bin/env python3
"""Stamp the stylesheet link with a hash of its contents.

Browsers cache assets/site.css aggressively. Without a changing query the
stylesheet stays stale even when the page itself is reloaded — which is how the
hero background appeared to vanish. Run after any CSS change.
"""
import hashlib, re, pathlib

h = hashlib.sha1(open("assets/site.css", "rb").read()).hexdigest()[:8]
changed = []
for p in list(pathlib.Path(".").glob("*.html")) + list(pathlib.Path("blog").rglob("*.html")) \
        + [pathlib.Path("assets/build_blog.py")]:
    if not p.exists():
        continue
    s = p.read_text(encoding="utf-8")
    new = re.sub(r'(site\.css)(\?v=[0-9a-f]+)?', r'\1?v=' + h, s)
    if new != s:
        p.write_text(new, encoding="utf-8")
        changed.append(str(p))
print(f"stamped site.css?v={h} in {len(changed)} file(s)")
for c in changed:
    print("  ", c)
