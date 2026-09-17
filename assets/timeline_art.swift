import AppKit
import Foundation

// Renders the NLE timeline behind the hero headline: video tracks whose clips
// carry real frames from the films, over audio tracks with waveforms.
// Deterministic — same output every run.
//
// Every thumbnail is a whole frame. Clip widths are multiples of one
// thumbnail, and frames are fitted rather than cropped, so nothing is sliced
// down the middle or cut off at a clip edge.
//
// Frames live in assets/img/timeline — stills taken away from the portfolio
// covers, so the hero does not repeat the grid below it.
//
//     swift assets/timeline_art.swift [framesDir]

let args = CommandLine.arguments
let framesDir = args.count > 1 ? args[1] : "assets/img/timeline"
var frames: [CGImage] = []
if let names = try? FileManager.default.contentsOfDirectory(atPath: framesDir) {
    for n in names.filter({ $0.hasSuffix(".jpg") }).sorted() {
        if let img = NSImage(contentsOfFile: (framesDir as NSString).appendingPathComponent(n)),
           let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) { frames.append(cg) }
    }
}
FileHandle.standardError.write("frames loaded: \(frames.count)\n".data(using: .utf8)!)

let W = 1600.0, H = 667.0
var seed: UInt64 = 20260917
func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double((seed >> 33) % 10000) / 10000.0 }

let img = NSImage(size: NSSize(width: W, height: H))
img.lockFocus()
let ground = NSColor(srgbRed: 0.13, green: 0.12, blue: 0.16, alpha: 1)
ground.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

NSColor(white: 1, alpha: 0.16).setFill()
var rx = 0.0
while rx < W { let tall = Int(rx) % 120 == 0
    NSRect(x: rx, y: H - (tall ? 20 : 11), width: 1, height: tall ? 20 : 11).fill(); rx += 20 }

let inset = 2.0, headerH = 6.0
var fi = 0

/// Draws one clip holding `count` complete thumbnails.
func drawClip(x: Double, y: Double, h: Double, count: Int) -> Double {
    let innerH = h - inset * 2 - headerH
    let thumbW = innerH * 16.0 / 9.0
    let w = thumbW * Double(count) + inset * 2
    let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: 3, yRadius: 3)
    NSGraphicsContext.current?.saveGraphicsState()
    path.setClip()
    NSColor(srgbRed: 0.20, green: 0.18, blue: 0.26, alpha: 1).setFill()
    NSRect(x: x, y: y, width: w, height: h).fill()
    for k in 0..<count {
        guard !frames.isEmpty else { break }
        let cg = frames[fi % frames.count]; fi += 1
        let cellX = x + inset + Double(k) * thumbW
        // fit, never crop: the whole frame sits inside its cell
        let s = min(thumbW / Double(cg.width), innerH / Double(cg.height))
        let dw = Double(cg.width) * s, dh = Double(cg.height) * s
        NSImage(cgImage: cg, size: .zero).draw(in: NSRect(
            x: cellX + (thumbW - dw) / 2, y: y + inset + (innerH - dh) / 2, width: dw, height: dh))
    }
    NSColor(srgbRed: 0.20, green: 0.17, blue: 0.29, alpha: 0.62).setFill()   // knock back
    NSRect(x: x, y: y, width: w, height: h).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    NSColor(white: 1, alpha: 0.13).setStroke(); path.lineWidth = 1; path.stroke()
    NSColor(srgbRed: 0.45, green: 0.35, blue: 0.77, alpha: 0.55).setFill()
    NSRect(x: x + 1, y: y + h - headerH - 1, width: w - 2, height: headerH).fill()
    return w
}

var trackY = H - 84.0
for _ in 0..<4 {
    var cx = 20.0 + rnd() * 40
    while cx < W - 60 {
        let count = rnd() > 0.62 ? 2 : 1            // mostly single frames, some pairs
        let w = drawClip(x: cx, y: trackY, h: 80, count: count)
        cx += w + 6 + rnd() * 26
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
