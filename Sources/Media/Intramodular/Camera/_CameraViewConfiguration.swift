//
// Copyright (c) Vatsal Manot
//

import CoreImage
import Swallow
import SwiftUI

public struct _CameraViewConfiguration: Hashable, Initiable, MergeOperatable {
    public var cameraPosition: CameraView._CameraPosition = .auto
    public var isMirrored: Bool?
    public var processingFrameRate: FrameRate?

    public init() {
        
    }
    
    public mutating func mergeInPlace(with other: _CameraViewConfiguration) {
        self.cameraPosition = other.cameraPosition
        self.isMirrored = other.isMirrored ?? self.isMirrored
        self.processingFrameRate = other.processingFrameRate ?? self.processingFrameRate
    }
}

extension _CameraViewConfiguration {
    public enum FrameRate: String, Codable, Hashable, Sendable {
        case fps1
        case fps15
        case fps30
        case fps60
        case fps120
        case fps240
        
        public var doubleValue: Double {
            switch self {
                case .fps1:
                    return 1
                case .fps15:
                    return 15
                case .fps30:
                    return 30
                case .fps60:
                    return 60
                case .fps120:
                    return 120
                case .fps240:
                    return 240
            }
        }
    }
}
