//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(visionOS)

import AVFoundation
import Swallow

extension AVCaptureDevice {
    @MainActor
    public class Authorization: ObservableObject {
        public static var shared = Authorization()
        
        private init() {
            #if canImport(UIKit)
            guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
                fatalError("NSCameraUsageDescription key must be present in the app's Info.plist to access the camera. This key should contain a message describing why the app needs access to the camera.")
            }
            #endif
        }
        
        public enum Status: Codable, Hashable, Sendable {
            case authorized
            case notDetermined
            case denied
            case restricted
            case unknown
        }
        
        @MainActor
        @Published public private(set) var status: Status = .notDetermined
        
        public func requestAccess() async -> Bool {
            let status: Status
            let result: Bool
            
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                    status = .authorized
                    result =  true
                case .notDetermined:
                    result = await withCheckedContinuation { continuation in
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            continuation.resume(returning: granted)
                            
                            if _isDebugAssertConfiguration, !granted {
                                runtimeIssue("Request to access the camera device for video capture was denied.")
                            }
                        }
                    }
                    status = result ? .authorized : .denied
                case .denied:
                    status = .denied
                    result = false
                case .restricted:
                    status = .restricted
                    result = false
                @unknown default:
                    status = .unknown
                    result = false
            }
            
            await MainActor.run {
                self.status = status
            }
            
            return result
        }
    }
}

#endif
