//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import Foundation
import Swift

extension AVPlayerItem {
    public convenience init(
        data: Data,
        fileTypeHint: AVFileType? = nil
    ) throws {
        let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        try data.write(to: temporaryFileURL)
        
        let asset = AVURLAsset(
            url: temporaryFileURL,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        self.init(asset: asset)
    }
}
