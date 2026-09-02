import AVFoundation
import AppKit
import Foundation

// Usage: swift contact_sheet.swift <video> <out.jpg> <count> <cols>
let args = CommandLine.arguments
guard args.count >= 5 else { print("need args"); exit(1) }
let url = URL(fileURLWithPath: args[1])
let outPath = args[2]
let count = Int(args[3]) ?? 40
let cols = Int(args[4]) ?? 8
let rows = Int(ceil(Double(count) / Double(cols)))

let asset = AVURLAsset(url: url)
let durSec = CMTimeGetSeconds(asset.duration)
guard durSec > 0 else { print("bad duration"); exit(1) }

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = CMTime(seconds: 0.3, preferredTimescale: 600)
gen.requestedTimeToleranceAfter = CMTime(seconds: 0.3, preferredTimescale: 600)

let cellW = 300, cellH = 169
let labelH = 20
let sheetW = cols * cellW
let sheetH = rows * (cellH + labelH)

let sheet = NSImage(size: NSSize(width: sheetW, height: sheetH))
sheet.lockFocus()
NSColor.black.setFill()
NSRect(x: 0, y: 0, width: sheetW, height: sheetH).fill()

let attrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor.yellow,
    .font: NSFont.systemFont(ofSize: 13, weight: .bold)
]

for i in 0..<count {
    let frac = (Double(i) + 0.5) / Double(count)
    let t = CMTime(seconds: durSec * frac, preferredTimescale: 600)
    guard let cg = try? gen.copyCGImage(at: t, actualTime: nil) else { continue }
    let col = i % cols
    let row = i / cols
    // NSImage origin is bottom-left; place rows top-to-bottom
    let x = col * cellW
    let y = sheetH - (row + 1) * (cellH + labelH)
    let img = NSImage(cgImage: cg, size: .zero)
    img.draw(in: NSRect(x: x, y: y + labelH, width: cellW, height: cellH))
    let pct = Int(frac * 100)
    let label = "\(i): \(pct)%"
    label.draw(at: NSPoint(x: x + 4, y: y + 2), withAttributes: attrs)
}

sheet.unlockFocus()
guard let tiff = sheet.tiffRepresentation,
      let bmp = NSBitmapImageRep(data: tiff),
      let jpg = bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
    print("encode fail"); exit(1)
}
try jpg.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) — \(count) frames, \(cols)x\(rows)")
