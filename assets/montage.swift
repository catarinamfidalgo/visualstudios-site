import AppKit
import Foundation

// Usage: swift montage.swift <out.jpg> <cols> <label:path> [label:path ...]
// Tiles cover images into one sheet so the grid's visual rhythm can be judged.
let a = CommandLine.arguments
guard a.count >= 4, let cols = Int(a[2]) else { print("need args"); exit(1) }
let items = a[3...].map { s -> (String, String) in
    let i = s.firstIndex(of: ":")!
    return (String(s[s.startIndex..<i]), String(s[s.index(after: i)...]))
}
let cellW = 320, cellH = 240, labelH = 26          // 4:3 cells, matching the site's cards
let rows = Int(ceil(Double(items.count) / Double(cols)))
let sheet = NSImage(size: NSSize(width: cols * cellW, height: rows * (cellH + labelH)))
sheet.lockFocus()
NSColor.black.setFill()
NSRect(x: 0, y: 0, width: cols * cellW, height: rows * (cellH + labelH)).fill()
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 15), .foregroundColor: NSColor.yellow]
for (n, item) in items.enumerated() {
    let r = n / cols, c = n % cols
    let y = (rows - 1 - r) * (cellH + labelH)
    if let img = NSImage(contentsOfFile: item.1) {
        // emulate object-fit: cover
        let s = max(CGFloat(cellW) / img.size.width, CGFloat(cellH) / img.size.height)
        let w = img.size.width * s, h = img.size.height * s
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: c * cellW, y: y + labelH, width: cellW, height: cellH)).setClip()
        img.draw(in: NSRect(x: CGFloat(c * cellW) - (w - CGFloat(cellW)) / 2,
                            y: CGFloat(y + labelH) - (h - CGFloat(cellH)) / 2, width: w, height: h))
        NSGraphicsContext.current?.restoreGraphicsState()
    }
    (item.0 as NSString).draw(at: NSPoint(x: c * cellW + 5, y: y + 4), withAttributes: attrs)
}
sheet.unlockFocus()
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])!
    .write(to: URL(fileURLWithPath: a[1]))
print("wrote \(a[1]) — \(items.count) covers, \(cols) cols")
