#!/usr/bin/swift
// Generates the shared Capri-and-white Handy emblem as a macOS iconset.
import Foundation
import CoreGraphics
import ImageIO

/// The Caslonian italic capital H outline (1000 units per em).
func caslonianItalicH() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 522, y: 661))
    path.addCurve(to: CGPoint(x: 589, y: 586),
                  control1: CGPoint(x: 595, y: 657),
                  control2: CGPoint(x: 611, y: 652))
    path.addLine(to: CGPoint(x: 512, y: 350))
    path.addLine(to: CGPoint(x: 218, y: 350))
    path.addLine(to: CGPoint(x: 294, y: 586))
    path.addCurve(to: CGPoint(x: 392, y: 661),
                  control1: CGPoint(x: 314, y: 646),
                  control2: CGPoint(x: 326, y: 657))
    path.addLine(to: CGPoint(x: 396, y: 675))
    path.addLine(to: CGPoint(x: 130, y: 675))
    path.addLine(to: CGPoint(x: 125, y: 661))
    path.addCurve(to: CGPoint(x: 192, y: 586),
                  control1: CGPoint(x: 197, y: 657),
                  control2: CGPoint(x: 214, y: 652))
    path.addLine(to: CGPoint(x: 30, y: 89))
    path.addCurve(to: CGPoint(x: -67, y: 14),
                  control1: CGPoint(x: 11, y: 29),
                  control2: CGPoint(x: -1, y: 18))
    path.addLine(to: CGPoint(x: -71, y: 0))
    path.addLine(to: CGPoint(x: 195, y: 0))
    path.addLine(to: CGPoint(x: 199, y: 14))
    path.addCurve(to: CGPoint(x: 133, y: 89),
                  control1: CGPoint(x: 127, y: 18),
                  control2: CGPoint(x: 111, y: 23))
    path.addLine(to: CGPoint(x: 213, y: 336))
    path.addLine(to: CGPoint(x: 508, y: 336))
    path.addLine(to: CGPoint(x: 427, y: 89))
    path.addCurve(to: CGPoint(x: 330, y: 14),
                  control1: CGPoint(x: 408, y: 29),
                  control2: CGPoint(x: 396, y: 18))
    path.addLine(to: CGPoint(x: 326, y: 0))
    path.addLine(to: CGPoint(x: 592, y: 0))
    path.addLine(to: CGPoint(x: 596, y: 14))
    path.addCurve(to: CGPoint(x: 530, y: 89),
                  control1: CGPoint(x: 524, y: 18),
                  control2: CGPoint(x: 508, y: 23))
    path.addLine(to: CGPoint(x: 691, y: 586))
    path.addCurve(to: CGPoint(x: 788, y: 661),
                  control1: CGPoint(x: 711, y: 646),
                  control2: CGPoint(x: 722, y: 657))
    path.addLine(to: CGPoint(x: 793, y: 675))
    path.addLine(to: CGPoint(x: 527, y: 675))
    path.closeSubpath()
    return path
}

func drawIcon(ctx: CGContext, size: CGFloat) {
    let background = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
        cornerWidth: size * 52 / 256,
        cornerHeight: size * 52 / 256,
        transform: nil
    )
    ctx.addPath(background)
    ctx.setFillColor(CGColor(red: 0, green: 188 / 255, blue: 242 / 255, alpha: 1))
    ctx.fillPath()

    var transform = CGAffineTransform(
        a: size * 0.0009375,
        b: 0,
        c: 0,
        d: size * 0.0009375,
        tx: size * 42 / 256,
        ty: size * 48 / 256
    )
    if let mark = caslonianItalicH().copy(using: &transform) {
        ctx.addPath(mark)
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fillPath()
    }
}

func savePNG(ctx: CGContext, path: String) {
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let destination = CGImageDestinationCreateWithURL(
        url, "public.png" as CFString, 1, nil
    ) else { return }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

let directory = "Handy.iconset"
try? FileManager.default.removeItem(atPath: directory)
try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

let specs: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for spec in specs {
    let pixels = spec.pixels
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: pixels * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create \(pixels) px context")
        continue
    }

    drawIcon(ctx: context, size: CGFloat(pixels))
    savePNG(ctx: context, path: "\(directory)/\(spec.name).png")
    print("  \(spec.name).png")
}

print("Iconset ready → \(directory)")
