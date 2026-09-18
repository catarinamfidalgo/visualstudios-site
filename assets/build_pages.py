#!/usr/bin/env python3
"""Split the site into separate pages.

assets/source.html is the single-page master and the only file to edit by
hand. It holds the fragments — header, hero, each
section, the footer and the script. This composes them into:

    /            hero, intro, featured work, CTA
    /work/       the full grid with filters
    /services/
    /about/
    /agencies/
    /contact/

Run after editing assets/source.html, then build_i18n.py for pt/ and es/.
"""
import os, re, pathlib, shutil

SRC = pathlib.Path("assets/source.html")  # the single-page master; pages are generated from it
SITE = "https://catarina.media"


def between(s, start_pat, end_pat):
    i = re.search(start_pat, s).start()
    j = re.search(end_pat, s[i:]).start() + i
    return s[i:j]


def extract(src):
    head = src[src.index("<head>"): src.index("</head>")]
    body = src[src.index("</head>") + len("</head>"):]
    frag = {}
    # starts at the language bar, which sits above the masthead
    frag["header"] = between(body, r'  <div class="lang-bar">', r'\n  <section class="hero-reed"')
    frag["hero"] = between(body, r'  <section class="hero-reed"', r'\n  <div class="container section" id="portfolio"')
    frag["portfolio"] = between(body, r'  <div class="container section" id="portfolio"', r'\n  <div class="container services section"')
    frag["services"] = between(body, r'  <div class="container services section"', r'\n  <div class="container section" id="about"')
    frag["about"] = between(body, r'  <div class="container section" id="about"', r'\n  <div class="container section" id="for-agencies"')
    frag["agencies"] = between(body, r'  <div class="container section" id="for-agencies"', r'\n  <div class="container section" id="contact"')
    frag["contact"] = between(body, r'  <div class="container section" id="contact"', r'\n  <footer class="site"')
    frag["footer"] = between(body, r'  <footer class="site"', r'\n  <div class="modal-overlay"')
    frag["modal"] = between(body, r'  <div class="modal-overlay"', r'\n  <script>')
    frag["script"] = body[body.index("  <script>"):]
    frag["head"] = head
    return frag


PAGES = [
    ("",          "Video Editor & Post-Production", ["hero", "portfolio"], True),
    ("services",  "Services",                       ["services"],           False),
    ("about",     "About",                          ["about"],              False),
    ("agencies",  "For Agencies",                   ["agencies"],           False),
    ("contact",   "Contact",                        ["contact"],            False),
]


def depth_fix(html, depth, slug=""):
    """Rewrite relative paths for a page that sits `depth` directories down."""
    up = "../" * depth
    html = re.sub(r'((?:href|src)=")(assets/)', r"\g<1>" + up + r"\g<2>", html)
    html = re.sub(r'((?:href|src)=")(blog/)', r"\g<1>" + up + r"\g<2>", html)
    html = html.replace("'assets/", "'" + up + "assets/")
    # the switcher should land on the same page in the other language
    tail = (slug + "/") if slug else ""
    html = html.replace('<a href="pt/">PT</a>', '<a href="%spt/%s">PT</a>' % (up, tail))
    html = html.replace('<a href="es/">ES</a>', '<a href="%ses/%s">ES</a>' % (up, tail))
    return html


def nav_for(slug, depth):
    up = "../" * depth if depth else ""
    items = [("", "Home"), ("#portfolio", "Portfolio"), ("services/", "Services"),
             ("about/", "About"), ("agencies/", "For Agencies"),
             ("blog/", "Blog"), ("contact/", "Contact")]
    out = []
    for href, label in items:
        cur = (href.rstrip("/") == slug)
        # the portfolio lives on the homepage, so link to its anchor
        target = (up + "#portfolio") if href == "#portfolio" and slug else ("#portfolio" if href == "#portfolio" else up + href)
        out.append('        <a href="%s"%s>%s</a>' % (target, ' class="active"' if cur else "", label))
    return "\n".join(out)


def build():
    src = SRC.read_text(encoding="utf-8")
    f = extract(src)

    for slug, title, parts, needs_js in PAGES:
        depth = 1 if slug else 0
        chunks = []
        for p in parts:
            chunks.append(featured if p == "featured" else f[p])

        head = f["head"]
        head = re.sub(r"<title>[^<]*</title>",
                      "<title>Catarina Fidalgo — %s</title>" % title, head)
        canon = SITE + "/" + (slug + "/" if slug else "")
        head = re.sub(r'(rel="canonical" href=")[^"]*(")', r"\g<1>%s\g<2>" % canon, head)
        head = re.sub(r'(og:url" content=")[^"]*(")', r"\g<1>%s\g<2>" % canon, head)

        body = f["header"].replace(f["header"][f["header"].index('      <nav class="main"'):
                                               f["header"].index("</nav>")],
                                   '      <nav class="main" id="siteNav">\n' + nav_for(slug, depth) + "\n      ")
        body += "\n".join(chunks) + "\n" + f["footer"] + f["modal"]
        body += f["script"] if needs_js else "  <script>\n  function toggleNav(b){var n=document.getElementById('siteNav');\n" \
                                             "    var o=n.classList.toggle('open');b.setAttribute('aria-expanded',o);}\n  </script>\n"

        page = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>" + head + "</head>\n<body>\n" + body + "</body>\n</html>\n"
        page = depth_fix(page, depth, slug)

        out = pathlib.Path(slug) / "index.html" if slug else pathlib.Path("index.html")
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page, encoding="utf-8")
        print("  built /%s" % (slug + "/" if slug else ""))


if __name__ == "__main__":
    build()
