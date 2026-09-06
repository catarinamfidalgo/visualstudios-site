import AppKit
import Foundation

// Usage: swift crop_bottom.swift <in.jpg> <out.jpg> <fractionToRemoveFromBottom>
// Trims burned-in subtitles off a frame before it is used as a cover.
let args = CommandLine.arguments
guard args.count >= 4, let frac = Double(args[3]) else { print("need args"); exit(1) }
guard let src = NSImage(contentsOfFile: args[1]),
      let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("cannot read \(args[1])"); exit(1)
}
let w = cg.width, h = cg.height
let keepH = Int(Double(h) * (1.0 - frac))
// CGImage origin is top-left, so cropping to keepH from y=0 drops the bottom band.
guard let cropped = cg.cropping(to: CGRect(x: 0, y: 0, width: w, height: keepH)) else {
    print("crop failed"); exit(1)
}
let rep = NSBitmapImageRep(cgImage: cropped)
guard let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
    print("encode failed"); exit(1)
}
try jpg.write(to: URL(fileURLWithPath: args[2]))
print("wrote \(args[2]) — \(w)x\(keepH) (was \(w)x\(h))")
