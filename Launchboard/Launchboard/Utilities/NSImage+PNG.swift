import AppKit

extension NSImage {
    /// Renders the image into a square PNG at the given pixel dimension.
    func pngData(sideLength: Int = 64) -> Data? {
        let size = NSSize(width: sideLength, height: sideLength)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: sideLength,
            pixelsHigh: sideLength,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        rep.size = size

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )

        return rep.representation(using: .png, properties: [:])
    }
}
