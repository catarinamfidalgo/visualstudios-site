import AppKit
import Foundation

// Renders an abstract NLE timeline for the hero background, in the site palette.
// Deterministic — same output every run.
let W = 1600.0, H = 667.0
var seed: UInt64 = 20260915
func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double((seed >> 33) % 10000) / 10000.0 }

let img = NSImage(size: NSSize(width: W, height: H))
img.lockFocus()
NSColor(srgbRed: 0.13, green: 0.12, blue: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// ruler ticks along the top
NSColor(white: 1, alpha: 0.18).setFill()
var x = 0.0
while x < W {
    let tall = Int(x) % 120 == 0
    NSRect(x: x, y: H - (tall ? 22 : 12), width: 1, height: tall ? 22 : 12).fill()
    x += 20
}

let lav = NSColor(srgbRed: 0.45, green: 0.35, blue: 0.77, alpha: 1)
let lavBright = NSColor(srgbRed: 0.66, green: 0.55, blue: 0.94, alpha: 1)
let slate = NSColor(srgbRed: 0.34, green: 0.32, blue: 0.41, alpha: 1)

func clip(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ c: NSColor) {
    let p = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: 3, yRadius: 3)
    c.setFill(); p.fill()
    NSColor(white: 1, alpha: 0.10).setStroke(); p.lineWidth = 1; p.stroke()
    // a lighter band along the top of each clip, as NLEs draw them
    NSColor(white: 1, alpha: 0.07).setFill()
    NSRect(x: x + 1, y: y + h - 7, width: w - 2, height: 6).fill()
}

// three video tracks
var trackY = H - 84.0
for t in 0..<4 {
    var cx = 20.0 + rnd() * 40
    while cx < W - 30 {
        let cw = 85 + rnd() * 215
        let c = (rnd() > 0.78) ? lav.withAlphaComponent(0.85)
              : (rnd() > 0.6 ? slate.blended(withFraction: 0.25, of: lavBright)! : slate)
        clip(cx, trackY, min(cw, W - 30 - cx), 80, c)
        cx += cw + 6 + rnd() * 26
    }
    trackY -= 88
    _ = t
}

// two audio tracks with waveforms
for _ in 0..<3 {
    var cx = 20.0 + rnd() * 60
    while cx < W - 30 {
        let cw = min(110 + rnd() * 240, W - 30 - cx)
        clip(cx, trackY, cw, 58, NSColor(srgbRed: 0.22, green: 0.28, blue: 0.33, alpha: 1))
        NSColor(srgbRed: 0.68, green: 0.88, blue: 0.92, alpha: 0.75).setFill()
        var wx = cx + 4
        while wx < cx + cw - 4 {
            let a = (2 + rnd() * 21)
            NSRect(x: wx, y: trackY + 29 - a / 2, width: 1.8, height: a).fill()
            wx += 3.2
        }
        cx += cw + 8 + rnd() * 30
    }
    trackY -= 68
}

// playhead
let px = W * 0.68
lavBright.withAlphaComponent(0.95).setFill()
NSRect(x: px, y: 0, width: 2, height: H - 6).fill()
NSBezierPath(roundedRect: NSRect(x: px - 7, y: H - 26, width: 16, height: 20), xRadius: 2, yRadius: 2).fill()

img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])!
    .write(to: URL(fileURLWithPath: "assets/img/hero-timeline.jpg"))
print("wrote assets/img/hero-timeline.jpg")
