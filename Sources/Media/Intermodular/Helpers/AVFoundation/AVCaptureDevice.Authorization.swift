//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(visionOS)

import AVFoundation

extension AVCaptureDevice {
    @MainActor
    public class Authorization {
        public init() {
            #if canImport(UIKit)
            guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
                fatalError("NSCameraUsageDescription key must be present in the app's Info.plist to access the camera. This key should contain a message describing why the app needs access to the camera.")
            }
            #endif
        }
        
        public func requestAccess() async -> Bool {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                    return true
                case .notDetermined:
                    // The user has not yet been asked for camera access
                    return await withCheckedContinuation { continuation in
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            continuation.resume(returning: granted)
                        }
                    }
                case .denied, .restricted:
                    return false
                @unknown default:
                    return false
            }
        }
    }
}

#endif
