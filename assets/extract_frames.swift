import AVFoundation
import AppKit
import Foundation

// Usage: swift extract_frames.swift <video> <outPrefix> <width>
let args = CommandLine.arguments
guard args.count >= 4 else { print("need args"); exit(1) }
let videoPath = args[1]
let outPrefix = args[2]
let targetW = CGFloat(Double(args[3]) ?? 1200)

let url = URL(fileURLWithPath: videoPath)
let asset = AVAsset(url: url)
let durSec = CMTimeGetSeconds(asset.duration)
guard durSec > 0 else { print("bad duration for \(videoPath)"); exit(1) }

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)  // was 1s: returned frames up to a second late

// Extra args (index 4+) are "tag:fraction" pairs; fall back to a default spread.
var fractions: [(String, Double)] = []
if args.count > 4 {
    for a in args[4...] {
        let parts = a.split(separator: ":")
        if parts.count == 2, let f = Double(parts[1]) {
            fractions.append((String(parts[0]), f))
        }
    }
}
if fractions.isEmpty {
    fractions = [("a", 0.25), ("b", 0.50), ("c", 0.75)]
}
for (tag, frac) in fractions {
    let t = CMTime(seconds: durSec * frac, preferredTimescale: 600)
    do {
        let cg = try gen.copyCGImage(at: t, actualTime: nil)
        let rep = NSBitmapImageRep(cgImage: cg)
        // scale to target width
        let scale = targetW / CGFloat(rep.pixelsWide)
        let newW = Int(targetW)
        let newH = Int(CGFloat(rep.pixelsHigh) * scale)
        let img = NSImage(size: NSSize(width: newW, height: newH))
        img.lockFocus()
        NSImage(cgImage: cg, size: .zero).draw(in: NSRect(x: 0, y: 0, width: newW, height: newH))
        img.unlockFocus()
        guard let tiff = img.tiffRepresentation,
              let bmp = NSBitmapImageRep(data: tiff),
              let jpg = bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
            print("encode fail \(tag)"); continue
        }
        let outPath = "\(outPrefix)-\(tag).jpg"
        try jpg.write(to: URL(fileURLWithPath: outPath))
        print("wrote \(outPath)")
    } catch {
        print("frame \(tag) failed: \(error)")
    }
}
