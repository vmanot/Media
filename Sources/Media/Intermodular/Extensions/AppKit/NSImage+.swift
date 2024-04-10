//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import AppKit

extension NSImage {
    public func pngData() -> Data? {
        guard let cgImage = cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            return nil
        }
        
        let rep = NSBitmapImageRep(cgImage: cgImage)
        
        guard let png = rep.representation(using: .png, properties: [:]) else { return nil }
        
        return png
    }
}

#endif
