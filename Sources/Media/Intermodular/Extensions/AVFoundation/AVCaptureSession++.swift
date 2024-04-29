//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS)

import AVFoundation
import SwiftUI

extension AVCaptureSession {
    public func withConfigurationScope(
        perform operation: () -> Void
    ) {
        beginConfiguration()
        operation()
        commitConfiguration()
    }
}

#endif
