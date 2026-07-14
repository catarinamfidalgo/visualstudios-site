# Visual Studios — website mirror

A clean, static mirror of [visualstudios.pro](https://visualstudios.pro) (originally built on
Carbonmade), rebuilt as plain HTML/CSS/JS for **GitHub Pages** — with a real contact form added.

## What's here

| File | Purpose |
|------|---------|
| `index.html` | Home — hero video, "Trusted by", client testimonials |
| `portfolio.html` | Portfolio — grid of 20 autoplay/loop/muted video reels |
| `about.html` | About — bio, showreel, testimonials |
| `contact.html` | Contact — **new 5-field form** (Name, Email, Company, Budget, Message) |
| `assets/style.css` | Shared design tokens + layout |
| `assets/media.js` | Lazy, viewport-aware video autoplay + reduced-motion handling |
| `assets/contact.js` | Contact form → `mailto:` handler |
| `assets/img/poster/` | Poster frames (the only self-hosted media) |

## How the media works

Images and videos are **hotlinked from the original Carbon CDN**
(`carbon-media.accelerator.net`) to keep this repo lightweight. Videos lazy-autoplay when scrolled
into view (muted, looping) and fall back to a poster + tap-to-play when the visitor has
"reduce motion" enabled.

> Note: because media is hotlinked, the site depends on that CDN staying online. If the original
> Carbonmade site is ever taken down, download the assets and swap the URLs for local paths — the
> markup stays the same. Poster frames are already generated with `ffmpeg`.

## The contact form

The original site had no form (only Calendly + email). This mirror adds one. It has no backend:
on submit, `assets/contact.js` encodes the fields into a `mailto:hello@visualstudios.pro` link and
opens the visitor's email client. Calendly and a plain `mailto:` link remain as fallbacks.

## Run locally

```bash
python3 -m http.server 8000
# open http://localhost:8000
```

## Deploy (GitHub Pages)

Pushed to GitHub with Pages served from `main` / root. To attach a custom domain later, add a
`CNAME` file containing the domain and set the DNS records GitHub provides — all internal links are
relative, so they work both under `/<repo>/` and at a domain root.

## Editing

- Text lives directly in the `.html` files.
- Colors/fonts are CSS variables at the top of `assets/style.css`.
- To add/remove a portfolio clip, copy a `.reel-card` block in `portfolio.html` and point
  `data-src` / `poster` at the new video id.
