//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS)

import AVFoundation
import SwiftUIX

#if os(macOS)
extension NSImage {
    convenience init?(
        sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation = .upMirrored
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        defer {
            CVPixelBufferUnlockBaseAddress(
                pixelBuffer,
                .readOnly
            )
        }
        
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        guard let cgImage = context.makeImage() else { return nil }
        
        self.init(cgImage: cgImage, size: NSZeroSize)
    }
}

extension AppKitOrUIKitImage {    
    public func write(
        to url: URL,
        type: NSBitmapImageRep.FileType = .png,
        properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
    ) throws {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            throw ImageWriteError.unableToCreateDataRepresentation
        }
        
        guard let data = bitmapImage.representation(using: type, properties: properties) else {
            throw ImageWriteError.unableToCreateDataRepresentation
        }
        
        do {
            try data.write(to: url)
        } catch {
            throw ImageWriteError.writeFailed(error)
        }
    }
    
    private enum ImageWriteError: Error {
        case unableToCreateDataRepresentation
        case writeFailed(Error)
    }
}
#endif

#endif
