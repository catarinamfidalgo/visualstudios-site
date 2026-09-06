#!/usr/bin/env python3
"""Emit montage arguments for the portfolio grid.

Mirrors renderGrid(): the card image is `poster` when set, falling back to the
first video's still. Reading media[0] directly shows the wrong image for any
project whose cover is deliberately not its first video (e.g. Danone).

    python3 assets/grid_preview.py [first] [last]
"""
import re, sys

src = open('index.html', encoding='utf-8').read()
block = src[src.index('const PROJECTS = ['):]
block = block[:block.index('\n  ];')]
rows = [l for l in block.split('\n') if l.strip().startswith("{brand:'")]

first = int(sys.argv[1]) if len(sys.argv) > 1 else 1
last = int(sys.argv[2]) if len(sys.argv) > 2 else len(rows)

out = []
for n, line in enumerate(rows, 1):
    if not (first <= n <= last):
        continue
    brand = re.search(r"brand:'((?:[^'\\]|\\.)*)'", line).group(1).replace("\\'", "")
    poster = re.search(r"poster:'([^']*)'", line).group(1)
    if not poster:
        m = re.search(r"media:\[\{video:'[^']*', gif:'([^']*)'", line)
        poster = m.group(1) if m else ''
    out.append(f"{n}-{brand[:12].replace(' ', '_')}:{poster}")
print(' '.join(out))
