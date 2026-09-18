#!/usr/bin/env python3
"""Render the blog from POSTS below.

Plain HTML out, no build tools, no dependencies — GitHub Pages serves it as-is.
Each post gets its own directory so the URL is /blog/<slug>/ rather than a .html
file, which reads better and is what search engines index.

    python3 assets/build_blog.py
"""
import os, re, html

SITE = "https://catarina.media"

POSTS = [
    {
        "slug": "ai-in-the-edit",
        "date": "2026-09-15",
        "date_label": "September 2026",
        "title": "I use AI in the edit. It doesn't do the editing.",
        "excerpt": "Clients have started asking whether AI can just do this now. "
                   "Here's the honest answer from inside the edit — what it genuinely helps with, "
                   "and the part it can't touch.",
        "body": """
<p class="lede">Clients have started asking me whether AI can just do this now. It's a fair
question and it deserves a straight answer rather than a defensive one, so here it is from
inside the edit.</p>

<p>I do use AI. Most editors I know do. But it does none of the editing, and the distinction
matters if you're the one paying for the result.</p>

<h3>What it's genuinely good at</h3>

<p>The honest list is longer than people who sell editing like to admit:</p>

<ul>
  <li><strong>Transcription.</strong> Two hours of interview becomes searchable text in minutes. This used to be an afternoon.</li>
  <li><strong>Rough selects.</strong> Point it at ten interviews and ask where somebody talks about pricing, and it will find the moments.</li>
  <li><strong>Audio cleanup.</strong> Room tone, hum, a bad lavalier — these are solved problems now.</li>
  <li><strong>Masking and rotoscoping.</strong> Work that was genuinely tedious and is now mostly not.</li>
  <li><strong>Subtitle timing.</strong> Still needs checking, but the first pass is close.</li>
</ul>

<p>Notice what those have in common. They're all <strong>labour</strong>. None of them is a
decision. Every one is a job I was happy to stop doing by hand, and none of them is the reason
a client hires me.</p>

<h3>What it can't do</h3>

<p><strong>Decide what the film is about.</strong> Ten interviews don't contain one story until
somebody chooses which one to tell. That choice isn't in the footage — it comes from
understanding what the client needs the film to achieve, which is usually not what the brief
says.</p>

<p><strong>Know which take carries it.</strong> Two takes can be identical on paper. One of
them lands and the other doesn't. The difference is a half-second of hesitation before an
answer, or an eye-line that reads as honest. A model scoring transcripts picks the clearest
sentence. The clearest sentence is often the least true one.</p>

<p><strong>Hold a pace.</strong> Knowing when to sit on a shot two seconds longer than is
comfortable, and when to cut away before the viewer is ready — that's the whole craft. It's
felt, against a specific audience, in a specific context.</p>

<p><strong>Be accountable.</strong> When a piece goes out under a brand's name, someone has to
have made the calls and be able to defend them.</p>

<h3>Where it actually goes wrong</h3>

<p>The failures are rarely dramatic. Nothing explodes. It's that the tool is confidently
slightly wrong, in ways you only catch if you already know what right looks like.</p>

<p><strong>Transcription outside English.</strong> I work in English, Portuguese and Spanish,
and the gap is obvious. English transcripts come back near-perfect. Portuguese comes back
readable but wrong in the places that matter — names, industry terms, and anything where a
speaker switches languages mid-sentence, which in my work happens constantly. It doesn't flag
uncertainty. It writes a plausible word and moves on. If you cut from the transcript without
watching, you'll cut a sentence the person didn't say.</p>

<p><strong>Selects that optimise for clarity.</strong> Ask a tool for the best answer to a
question and it returns the most articulate one. But in a testimonial, the most articulate
answer is often the most rehearsed, and rehearsed doesn't persuade. The take you want is
usually the one where somebody pauses, corrects themselves, and then says the true thing. On a
transcript that looks like the worse option.</p>

<p><strong>Auto-reframe.</strong> Useful for turning a landscape cut into vertical, right up
until the moment two people are talking and it decides which one matters. It follows movement,
not meaning, so it will drift off the person listening — and in an interview, the reaction is
frequently the shot.</p>

<p><strong>Noise reduction pushed too far.</strong> It's excellent at removing hum. It is also
happy to remove the room, and a voice with no room around it sounds like a voice in a box.
Nobody can say why the video feels cheap; it just does.</p>

<p><strong>Automatic colour matching.</strong> It will make your shots consistent by making
them average. If the look was deliberate — warm, cool, deliberately flat — average is exactly
wrong.</p>

<p>None of this makes the tools bad. It makes them tools. Every one of these is fine when
somebody is watching the output and knows what they're looking for.</p>

<h3>How I use it</h3>

<p>Sparingly, and always pointed at something. A transcript so I can navigate an interview by
text instead of scrubbing. Noise reduction on a take that's otherwise the best one. Never for
the structure, never for the selects, never for the pacing.</p>

<p>The tool is fast at the parts that were slow. It's useless at the parts that were hard.</p>

<h3>If you're the one hiring</h3>

<p>An AI-assembled edit tends to look fine the first time you watch it and hollow the second.
The cuts are on the beat, the information is present, and nothing quite lands. If your video
exists to persuade somebody — to trust a brand, to take a training seriously, to book
something — then pacing <em>is</em> the persuasion, and that's precisely the part nothing has
automated.</p>

<p>Use the tools. Just don't confuse the labour with the work.</p>
"""
    },
]

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — Catarina Fidalgo</title>
<meta name="description" content="{excerpt}">
<link rel="canonical" href="{canonical}">
<link rel="icon" href="{root}assets/favicon.svg" type="image/svg+xml">
<meta property="og:type" content="article">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{excerpt}">
<meta property="og:url" content="{canonical}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{root}assets/site.css?v=f22be881">
</head>
<body>
{header}
{main}
{footer}
</body>
</html>
"""

def header(root):
    return f"""  <div class="container">
    <header class="site">
      <div class="brand"><a href="{root}">Catarina <i>Fidalgo</i></a></div>
      <nav class="main" id="siteNav">
        <a href="{root}">Home</a>
        <a href="{root}#portfolio">Portfolio</a>
        <a href="{root}services/">Services</a>
        <a href="{root}about/">About</a>
        <a href="{root}agencies/">For Agencies</a>
        <a href="{root}blog/" class="active">Blog</a>
        <a href="{root}contact/">Contact</a>
      </nav>
    </header>
  </div>"""

def footer(root):
    return f"""  <footer class="site">
    <div class="container">
      <div class="foot-brand">
        <div class="foot-logo">Catarina <i>Fidalgo</i></div>
        <div class="foot-tag">Made in the edit</div>
        <div class="copy">&copy; 2026 Catarina Fidalgo &middot; All rights reserved</div>
      </div>
      <div class="foot-cta">
        <a class="btn btn--ghost-light" href="{root}index.html#contact">Start a project</a>
      </div>
    </div>
  </footer>"""

def build():
    os.makedirs("blog", exist_ok=True)
    # individual posts
    for p in POSTS:
        d = os.path.join("blog", p["slug"])
        os.makedirs(d, exist_ok=True)
        root = "../../"
        main = f"""  <div class="container section">
    <article class="article">
      <div class="article-meta">{p['date_label']}</div>
      <h1>{p['title']}</h1>
      {p['body'].strip()}
      <a class="back-link" href="{root}blog/">&larr; All posts</a>
    </article>
  </div>"""
        open(os.path.join(d, "index.html"), "w", encoding="utf-8").write(PAGE.format(
            title=html.escape(p["title"], quote=True), excerpt=html.escape(p["excerpt"], quote=True),
            canonical=f"{SITE}/blog/{p['slug']}/", root=root,
            header=header(root), main=main, footer=footer(root)))
    # index
    root = "../"
    items = "\n".join(
        f"""        <li class="post-item"><a href="{root}blog/{p['slug']}/">
          <div class="post-date">{p['date_label']}</div>
          <h2 class="post-title">{p['title']}</h2>
          <p class="post-excerpt">{p['excerpt']}</p>
        </a></li>""" for p in POSTS)
    main = f"""  <div class="container section">
    <h2 class="eyebrow">Blog</h2>
    <p class="copy">Notes on editing, post-production, and working with video.</p>
    <ul class="post-list">
{items}
    </ul>
  </div>"""
    open("blog/index.html", "w", encoding="utf-8").write(PAGE.format(
        title="Blog", excerpt="Notes on editing, post-production, and working with video.",
        canonical=f"{SITE}/blog/", root=root,
        header=header(root), main=main, footer=footer(root)))
    print(f"built blog/index.html and {len(POSTS)} post page(s)")

if __name__ == "__main__":
    build()
