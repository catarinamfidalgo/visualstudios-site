#!/usr/bin/env python3
"""Check every YouTube id wired into the site.

For each video with a `yt` id: confirm the video exists, is embeddable, and
that its length matches the local master. Duration is what catches a
plausible-but-wrong pairing — two videos on the same topic, same channel,
different cut.

    python3 assets/verify_ids.py
"""
import json, os, re, subprocess, sys, urllib.request

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120 Safari/537.36")


def local_seconds(path):
    if not os.path.exists(path):
        return None
    out = subprocess.run(["mdls", "-name", "kMDItemDurationSeconds", path],
                         capture_output=True, text=True).stdout
    try:
        return float(out.split("=")[1])
    except (IndexError, ValueError):
        return None


def youtube_meta(vid):
    """Fetch video metadata. Uses curl: this Python has no CA bundle, so
    urllib fails TLS verification on every request."""
    url = f"https://www.youtube.com/watch?v={vid}&ucbcb=1"
    proc = subprocess.run(
        ["curl", "-sL", "--max-time", "30", "-A", UA,
         "-H", "Accept-Language: en-US,en;q=0.9", url],
        capture_output=True, text=True, errors="ignore")
    if proc.returncode != 0:
        return {"network_error": f"curl exit {proc.returncode}"}
    html = proc.stdout
    if len(html) < 5000:
        return {"network_error": f"short response ({len(html)} bytes)"}

    def grab(pat):
        m = re.search(pat, html)
        return m.group(1) if m else None

    return {
        "title": grab(r'<meta name="title" content="([^"]*)"'),
        "channel": grab(r'"ownerChannelName":"([^"]*)"'),
        "seconds": float(grab(r'"lengthSeconds":"(\d+)"') or 0),
        "views": grab(r'"viewCount":"(\d+)"'),
        "playable": '"status":"OK"' in html,
    }


def main():
    src = open("index.html", encoding="utf-8").read()
    block = src[src.index("const PROJECTS = ["):]
    block = block[:block.index("\n  ];")]

    checked = problems = 0
    for line in block.split("\n"):
        if not line.strip().startswith("{brand:'"):
            continue
        brand = re.search(r"brand:'((?:[^'\\]|\\.)*)'", line).group(1).replace("\\'", "'")
        for video, vid in re.findall(r"video:'([^']*)', yt:'([^']*)'", line):
            checked += 1
            meta = youtube_meta(vid)
            local = local_seconds(video)
            name = os.path.basename(video)
            if meta.get("network_error"):
                print(f"  CHECK FAILED {brand} / {name}: {meta['network_error']}")
                problems += 1
                continue
            if not meta.get("title"):
                print(f"  UNAVAILABLE  {brand} / {name} -> {vid} (deleted or private?)")
                problems += 1
                continue
            drift = abs(meta["seconds"] - local) if local else None
            if drift is not None and drift > 3:
                print(f"  MISMATCH     {brand} / {name}")
                print(f"               local {local:.0f}s vs youtube {meta['seconds']:.0f}s"
                      f"  ({meta['title'][:52]})")
                problems += 1
            elif not meta["playable"]:
                print(f"  NOT PLAYABLE {brand} / {name} -> {vid}")
                problems += 1
            else:
                print(f"  ok           {brand} / {name}  {meta['views'] or '?'} views")
    print(f"\n{checked} checked, {problems} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
