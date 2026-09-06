import AppKit
import Foundation

// Usage: swift crop_frame.swift <in.jpg> <out.jpg> <left> <top> <right> <bottom>
// Each value is the fraction to trim off that edge (0 = keep all).
// Used to remove burned-in animated text from a frame before using it as a cover.
let a = CommandLine.arguments
guard a.count >= 7,
      let l = Double(a[3]), let t = Double(a[4]),
      let r = Double(a[5]), let b = Double(a[6]) else { print("need args"); exit(1) }
guard let src = NSImage(contentsOfFile: a[1]),
      let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("cannot read \(a[1])"); exit(1)
}
let w = Double(cg.width), h = Double(cg.height)
let rect = CGRect(x: w * l, y: h * t, width: w * (1 - l - r), height: h * (1 - t - b))
guard rect.width > 1, rect.height > 1, let out = cg.cropping(to: rect) else {
    print("bad crop rect"); exit(1)
}
let rep = NSBitmapImageRep(cgImage: out)
guard let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
    print("encode failed"); exit(1)
}
try jpg.write(to: URL(fileURLWithPath: a[2]))
print("wrote \(a[2]) — \(Int(rect.width))x\(Int(rect.height)) (was \(Int(w))x\(Int(h)))")
