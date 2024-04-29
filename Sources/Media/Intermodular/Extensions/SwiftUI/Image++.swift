//
// Copyright (c) Vatsal Manot
//

#if canImport(CoreVideo)
import CoreVideo
#endif
import SwiftUIX
#if canImport(VideoToolbox)
import VideoToolbox
#endif

#if canImport(CoreVideo) && canImport(VideoToolbox)
extension Image {
    public init?(
        cvImage image: CVImageBuffer
    ) {
        guard let image: AppKitOrUIKitImage = image._appKitOrUIKitImage else {
            return nil
        }
        
        self.init(image: image)
    }
}
#endif
