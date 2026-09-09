import AppKit
import Foundation

// Fits a non-16:9 frame onto a 1280x720 canvas: the whole frame centred and
// intact, over a blurred, enlarged copy of itself. Cropping verticals to 16:9
// cuts people's heads off; this keeps the shot whole.
let a = CommandLine.arguments
guard a.count >= 3, let src = NSImage(contentsOfFile: a[1]),
      let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("usage: fit_16x9 <in> <out>"); exit(1)
}
let W = 1280.0, H = 720.0
let iw = Double(cg.width), ih = Double(cg.height)

let out = NSImage(size: NSSize(width: W, height: H))
out.lockFocus()

// background: scale to cover, blur heavily, darken
let ci = CIImage(cgImage: cg)
let cover = max(W / iw, H / ih) * 1.15
let blur = CIFilter(name: "CIGaussianBlur")!
blur.setValue(ci.transformed(by: CGAffineTransform(scaleX: cover, y: cover)), forKey: kCIInputImageKey)
blur.setValue(38.0, forKey: kCIInputRadiusKey)
if let b = blur.outputImage {
    let rep = NSCIImageRep(ciImage: b)
    let bg = NSImage(size: rep.size); bg.addRepresentation(rep)
    let bw = iw * cover, bh = ih * cover
    bg.draw(in: NSRect(x: (W - bw) / 2, y: (H - bh) / 2, width: bw, height: bh))
}
NSColor(calibratedWhite: 0, alpha: 0.28).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// foreground: whole frame, scaled to fit, centred
let fit = min(W / iw, H / ih)
let fw = iw * fit, fh = ih * fit
NSImage(cgImage: cg, size: .zero).draw(in: NSRect(x: (W - fw) / 2, y: (H - fh) / 2, width: fw, height: fh))
out.unlockFocus()

let rep = NSBitmapImageRep(data: out.tiffRepresentation!)!
try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.88])!
    .write(to: URL(fileURLWithPath: a[2]))
print("  fitted \((a[2] as NSString).lastPathComponent)")
