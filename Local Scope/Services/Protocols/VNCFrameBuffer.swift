//
//  VNCFrameBuffer.swift
//  Local Scope
//

import Foundation
import CoreGraphics

struct VNCFrameBuffer: Sendable, Equatable {
    let width: Int
    let height: Int
    let bytesPerPixel: Int
    let pixels: [UInt8]

    static let empty = VNCFrameBuffer(width: 0, height: 0, bytesPerPixel: 4, pixels: [])

    var bytesPerRow: Int {
        width * bytesPerPixel
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    func replacing(region: VNCFrameRegion, with replacementPixels: [UInt8]) -> VNCFrameBuffer {
        guard width > 0, height > 0, bytesPerPixel > 0 else { return self }
        guard region.width > 0, region.height > 0 else { return self }

        let expectedByteCount = region.width * region.height * bytesPerPixel
        guard replacementPixels.count == expectedByteCount else { return self }

        var updatedPixels = pixels
        guard updatedPixels.count == width * height * bytesPerPixel else { return self }

        for row in 0..<region.height {
            let destinationStart = ((region.y + row) * width + region.x) * bytesPerPixel
            let sourceStart = row * region.width * bytesPerPixel
            let rowLength = region.width * bytesPerPixel

            guard destinationStart >= 0,
                  destinationStart + rowLength <= updatedPixels.count,
                  sourceStart + rowLength <= replacementPixels.count else { continue }

            updatedPixels.replaceSubrange(
                destinationStart..<(destinationStart + rowLength),
                with: replacementPixels[sourceStart..<(sourceStart + rowLength)]
            )
        }

        return VNCFrameBuffer(
            width: width,
            height: height,
            bytesPerPixel: bytesPerPixel,
            pixels: updatedPixels
        )
    }
}
