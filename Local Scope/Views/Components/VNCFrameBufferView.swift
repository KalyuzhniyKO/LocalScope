//
//  VNCFrameBufferView.swift
//  Local Scope
//

import SwiftUI
import AppKit
import CoreGraphics

struct VNCFrameBufferView: View {
    let frameBuffer: VNCFrameBuffer

    var body: some View {
        Group {
            if let image = nsImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "display")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Ожидание framebuffer от native VNC backend")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.65))
            }
        }
    }

    private var nsImage: NSImage? {
        guard frameBuffer.width > 0,
              frameBuffer.height > 0,
              frameBuffer.pixels.count == frameBuffer.width * frameBuffer.height * frameBuffer.bytesPerPixel,
              let provider = CGDataProvider(data: Data(frameBuffer.pixels) as CFData) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let cgImage = CGImage(
            width: frameBuffer.width,
            height: frameBuffer.height,
            bitsPerComponent: 8,
            bitsPerPixel: frameBuffer.bytesPerPixel * 8,
            bytesPerRow: frameBuffer.bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: frameBuffer.size)
    }
}
