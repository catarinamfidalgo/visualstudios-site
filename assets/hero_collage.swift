import AppKit
import Foundation

// Builds a seamless grid of frames for the hero background — no gaps, no labels.
// Usage: hero_collage <out.jpg> <cols> <rows> <width> <height> <images...>
let a = CommandLine.arguments
guard a.count >= 7, let cols = Int(a[2]), let rows = Int(a[3]),
      let W = Double(a[4]), let H = Double(a[5]) else { print("bad args"); exit(1) }
let paths = Array(a[6...])
let cw = W / Double(cols), ch = H / Double(rows)
let out = NSImage(size: NSSize(width: W, height: H))
out.lockFocus()
NSColor.black.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
for i in 0..<(cols * rows) {
    guard i < paths.count, let img = NSImage(contentsOfFile: paths[i]),
          let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
    let c = i % cols, r = i / cols
    let x = Double(c) * cw, y = H - Double(r + 1) * ch
    // fill the cell, cropping overflow
    let s = max(cw / Double(cg.width), ch / Double(cg.height))
    let dw = Double(cg.width) * s, dh = Double(cg.height) * s
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(rect: NSRect(x: x, y: y, width: cw, height: ch)).setClip()
    NSImage(cgImage: cg, size: .zero).draw(in: NSRect(x: x - (dw - cw) / 2, y: y - (dh - ch) / 2, width: dw, height: dh))
    NSGraphicsContext.current?.restoreGraphicsState()
}
out.unlockFocus()
let rep = NSBitmapImageRep(data: out.tiffRepresentation!)!
try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.72])!
    .write(to: URL(fileURLWithPath: a[1]))
print("wrote \(a[1]) — \(cols)x\(rows)")
