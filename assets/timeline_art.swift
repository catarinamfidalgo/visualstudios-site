import AppKit
import Foundation

// Renders an NLE timeline for the hero: video tracks whose clips carry real
// frames from the portfolio, the way Final Cut shows thumbnails, over audio
// tracks with waveforms. Deterministic — same output every run.
// Usage: timeline_art <framesDir>
let args = CommandLine.arguments
let framesDir = args.count > 1 ? args[1] : ""
var frames: [CGImage] = []
if !framesDir.isEmpty, let names = try? FileManager.default.contentsOfDirectory(atPath: framesDir) {
    for n in names.filter({ $0.hasSuffix(".jpg") }).sorted() {
        if let img = NSImage(contentsOfFile: (framesDir as NSString).appendingPathComponent(n)),
           let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) { frames.append(cg) }
    }
}
FileHandle.standardError.write("frames loaded: \(frames.count)\n".data(using: .utf8)!)

let W = 1600.0, H = 667.0
var seed: UInt64 = 20260916
func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double((seed >> 33) % 10000) / 10000.0 }

let img = NSImage(size: NSSize(width: W, height: H))
img.lockFocus()
NSColor(srgbRed: 0.13, green: 0.12, blue: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// ruler
NSColor(white: 1, alpha: 0.16).setFill()
var rx = 0.0
while rx < W { let tall = Int(rx) % 120 == 0
    NSRect(x: rx, y: H - (tall ? 20 : 11), width: 1, height: tall ? 20 : 11).fill(); rx += 20 }

var fi = 0
func clipWithFrame(_ x: Double, _ y: Double, _ w: Double, _ h: Double) {
    let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: 3, yRadius: 3)
    NSGraphicsContext.current?.saveGraphicsState()
    path.setClip()
    if frames.isEmpty {
        NSColor(srgbRed: 0.34, green: 0.32, blue: 0.41, alpha: 1).setFill()
        NSRect(x: x, y: y, width: w, height: h).fill()
    } else {
        // tile the clip with successive frames, as a real timeline does
        var tx = x
        let tw = h * 16.0 / 9.0 * 0.62          // each thumbnail a little narrower than 16:9
        while tx < x + w {
            let cg = frames[fi % frames.count]; fi += 1
            let s = max(tw / Double(cg.width), h / Double(cg.height))
            let dw = Double(cg.width) * s, dh = Double(cg.height) * s
            NSGraphicsContext.current?.saveGraphicsState()
            NSBezierPath(rect: NSRect(x: tx, y: y, width: min(tw, x + w - tx), height: h)).setClip()
            NSImage(cgImage: cg, size: .zero).draw(in: NSRect(x: tx - (dw - tw) / 2, y: y - (dh - h) / 2, width: dw, height: dh))
            NSGraphicsContext.current?.restoreGraphicsState()
            tx += tw
        }
        // knock the frames back so the headline stays dominant
        NSColor(srgbRed: 0.13, green: 0.12, blue: 0.16, alpha: 0.34).setFill()
        NSRect(x: x, y: y, width: w, height: h).fill()
    }
    NSGraphicsContext.current?.restoreGraphicsState()
    NSColor(white: 1, alpha: 0.13).setStroke(); path.lineWidth = 1; path.stroke()
    NSColor(srgbRed: 0.45, green: 0.35, blue: 0.77, alpha: 0.55).setFill()   // clip header bar
    NSRect(x: x + 1, y: y + h - 7, width: w - 2, height: 6).fill()
}

var trackY = H - 84.0
for _ in 0..<4 {
    var cx = 20.0 + rnd() * 40
    while cx < W - 30 {
        let cw = 85 + rnd() * 215
        clipWithFrame(cx, trackY, min(cw, W - 30 - cx), 80)
        cx += cw + 6 + rnd() * 26
    }
    trackY -= 88
}

for _ in 0..<3 {
    var cx = 20.0 + rnd() * 60
    while cx < W - 30 {
        let cw = min(110 + rnd() * 240, W - 30 - cx)
        let p = NSBezierPath(roundedRect: NSRect(x: cx, y: trackY, width: cw, height: 58), xRadius: 3, yRadius: 3)
        NSColor(srgbRed: 0.22, green: 0.28, blue: 0.33, alpha: 1).setFill(); p.fill()
        NSColor(white: 1, alpha: 0.10).setStroke(); p.lineWidth = 1; p.stroke()
        NSColor(srgbRed: 0.68, green: 0.88, blue: 0.92, alpha: 0.75).setFill()
        var wx = cx + 4
        while wx < cx + cw - 4 {
            let a = (2 + rnd() * 21)
            NSRect(x: wx, y: trackY + 29 - a / 2, width: 1.8, height: a).fill(); wx += 3.2
        }
        cx += cw + 8 + rnd() * 30
    }
    trackY -= 68
}

img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.78])!
    .write(to: URL(fileURLWithPath: "assets/img/hero-timeline.jpg"))
print("wrote assets/img/hero-timeline.jpg")
