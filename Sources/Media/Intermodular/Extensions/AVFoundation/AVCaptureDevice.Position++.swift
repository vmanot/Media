//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS)

import AVFoundation
import SwiftUI

extension AVCaptureDevice.Position {
    public init(_from position: _CameraViewConfiguration.CameraPosition) {
        switch position {
            case .auto:
                self = .unspecified
            case .back:
                self = .back
            case .front:
                self = .front
        }
    }
}

#endif
