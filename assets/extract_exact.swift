import AVFoundation
import AppKit
import Foundation

// Frame-accurate extraction. extract_frames.swift allows a second of tolerance
// after the requested time, which is fine when sampling a spread but wrong when
// a specific frame is wanted.
let a = CommandLine.arguments
guard a.count >= 4 else { print("usage: extract_exact <video> <outPrefix> <seconds...>"); exit(1) }
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
for s in a[3...] {
    guard let t = Double(s) else { continue }
    guard let cg = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) else {
        print("  failed at \(t)s"); continue
    }
    let rep = NSBitmapImageRep(cgImage: cg)
    let out = "\(a[2])-\(s.replacingOccurrences(of: ".", with: "_")).jpg"
    try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
        .write(to: URL(fileURLWithPath: out))
    print("  wrote \(out)")
}
