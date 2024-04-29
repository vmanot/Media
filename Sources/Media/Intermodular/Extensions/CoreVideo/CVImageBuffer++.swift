//
// Copyright (c) Vatsal Manot
//

#if canImport(CoreVideo) && canImport(VideoToolbox)

import CoreVideo
import SwiftUIX
import VideoToolbox

extension CVImageBuffer {
    public var _cgImage: CGImage? {
        var cgImage: CGImage!
        
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        
        return cgImage
    }
    
    public var _appKitOrUIKitImage: AppKitOrUIKitImage? {
        guard let image: CGImage = self._cgImage else {
            return nil
        }
        
#if os(iOS)
        return AppKitOrUIKitImage(cgImage: image)
#else
        return AppKitOrUIKitImage(
            cgImage: image,
            size: CGSize(width: image.width, height: image.height)
        )
#endif
    }
}

#endif
