#!/usr/bin/env python3
"""Generate the translated sites from index.html.

English stays the single source. Run this after any change to index.html and the
translated versions follow, rather than three files drifting apart.

    python3 assets/build_i18n.py
"""
import importlib.util, os, re, sys

LANGS = {"pt": "assets/i18n_pt.py", "es": "assets/i18n_es.py"}


def load(path):
    spec = importlib.util.spec_from_file_location("t", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def translate_projects(block, t):
    """Swap types, tasks, industries and descriptions inside the PROJECTS data."""
    out = []
    for line in block.split("\n"):
        if not line.lstrip().startswith("{brand:'"):
            out.append(line)
            continue
        brand = re.search(r"brand:'((?:[^'\\]|\\.)*)'", line).group(1).replace("\\'", "'")

        def sub_list(key, table, l):
            m = re.search(key + r":\[([^\]]*)\]", l)
            if not m:
                return l
            vals = re.findall(r"'([^']*)'", m.group(1))
            new = ", ".join("'%s'" % table.get(v, v) for v in vals)
            return l.replace(m.group(0), f"{key}:[{new}]")

        line = sub_list("types", t.TYPES, line)
        line = sub_list("industries", t.INDUSTRIES, line)

        m = re.search(r"tasks:'([^']*)'", line)
        if m and m.group(1):
            parts = [t.TASKS.get(x.strip(), x.strip()) for x in m.group(1).split(",") if x.strip()]
            line = line.replace(m.group(0), "tasks:'%s'" % ", ".join(parts))

        if brand in t.DESCS:
            m = re.search(r"desc:'((?:[^'\\]|\\.)*)'", line)
            line = line.replace(m.group(0), "desc:'%s'" % t.DESCS[brand])
        out.append(line)
    return "\n".join(out)


def build(lang, path):
    t = load(path)
    s = open("index.html", encoding="utf-8").read()

    # 1. project data
    i = s.index("const PROJECTS = [")
    j = s.index("\n  ];", i)
    s = s[:i] + translate_projects(s[i:j], t) + s[j:]

    # 2. interface, services, body copy — longest first so substrings don't
    #    clobber the longer phrases that contain them.
    #    Brand names are masked first: "Apex Imaging Services" must not become
    #    "Apex Imaging Serviços" because the table contains "Services".
    brands = re.findall(r"brand:'((?:[^'\\]|\\.)*)'", s)
    masks = {}
    for n, br in enumerate(sorted(set(brands), key=len, reverse=True)):
        token = "\x00BRAND%d\x00" % n
        masks[token] = br
        s = s.replace("brand:'%s'" % br, "brand:'%s'" % token)

    table = {}
    for d in (t.UI, t.SERVICES, t.COPY, t.TYPES):  # TYPES also appear in the form's <option> list
        table.update(d)
    for src in sorted(table, key=len, reverse=True):
        s = s.replace(src, table[src])

    for token, br in masks.items():
        s = s.replace(token, br)

    # 3. metadata
    s = re.sub(r"<title>[^<]*</title>", "<title>%s</title>" % t.META["title"], s)
    s = re.sub(r'(name="description" content=")[^"]*(")', r"\g<1>%s\g<2>" % t.META["description"], s)
    s = re.sub(r'(og:description" content=")[^"]*(")', r"\g<1>%s\g<2>" % t.META["description"], s)
    s = s.replace('<html lang="en">', '<html lang="%s">' % {"pt": "pt-PT", "es": "es-ES"}.get(lang, lang))

    # 4. paths — the page now lives one directory down
    s = re.sub(r'((?:href|src)=")(assets/)', r"\g<1>../\g<2>", s)
    s = re.sub(r'((?:href|src)=")(blog/)', r"\g<1>../\g<2>", s)
    s = s.replace("'assets/video/", "'../assets/video/").replace("'assets/img/", "'../assets/img/")

    # 5. language switcher: this language becomes current, the others link out
    others = [x for x in ["en", "pt", "es"] if x != lang]
    sw = ['        <a href="../">EN</a>' if lang != "en" else '        <span class="lang-current">EN</span>']
    for code in ["pt", "es"]:
        if code == lang:
            sw.append('        <span class="lang-current">%s</span>' % code.upper())
        else:
            sw.append('        <a href="../%s/">%s</a>' % (code, code.upper()))
    s = re.sub(r'\s*<span class="lang-current"[^>]*>EN</span>\n\s*<a href="\.\./?pt/?">PT</a>\n\s*<a href="\.\./?es/?">ES</a>',
               "\n" + "\n".join(sw), s)
    s = re.sub(r'\s*<span class="lang-current"[^>]*>EN</span>\n\s*<a href="pt/">PT</a>\n\s*<a href="es/">ES</a>',
               "\n" + "\n".join(sw), s)

    os.makedirs(lang, exist_ok=True)
    open(os.path.join(lang, "index.html"), "w", encoding="utf-8").write(s)
    print(f"built {lang}/index.html")


if __name__ == "__main__":
    for lang, path in LANGS.items():
        if os.path.exists(path):
            build(lang, path)
