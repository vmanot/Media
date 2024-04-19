//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import Swift

#if os(iOS) || os(tvOS) || os(visionOS)
public final class _AVAudioSession: ObservableObject {
    public static let shared: _AVAudioSession = _AVAudioSession(base: .sharedInstance())
    
    private let base: AVAudioSession
    
    private init(base: AVAudioSession) {
        self.base = base
    }
    
    public func enableBuiltInMicIfPossible() throws {
        guard let availableInputs = base.availableInputs, let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            return
        }
        
        try base.setPreferredInput(builtInMicInput)
    }
        
    public func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: base
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: base
        )
    }
    
    @objc private func handleAudioSessionInterruption(
        notification: Notification
    ) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            objectWillChange.send()
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

                if options.contains(.shouldResume) {
                    objectWillChange.send()
                }
            }
        }
    }
    
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
            case .newDeviceAvailable, .oldDeviceUnavailable:
                objectWillChange.send()
            default:
                break
        }
    }
}

extension _AVAudioSession {
    public func setActive(_ active: Bool) throws {
        try base.setActive(active)
    }
    
    public func setCategory(_ category: Category, mode: Mode) throws {
        try base.setCategory(AVAudioSession.Category(category), mode: .init(mode))
    }
}
#else
public struct _AVAudioSession {
    public static let shared = Self()
}

extension _AVAudioSession {
    public func setActive(_ active: Bool) throws {
        
    }
    
    public func setCategory(_ category: Category, mode: Mode) throws {
        
    }
}
#endif

// MARK: - Supplementary

// MARK: - Auxiliary

extension _AVAudioSession {
    @frozen
    public enum Category {
        case ambient
        case soloAmbient
        case playback
        case record
        case playAndRecord
        case unknown
    }
    
    @frozen
    public enum Mode {
        case `default`
        case voiceChat
        case gameChat
        case videoRecording
        case measurement
        case moviePlayback
        case videoChat
        case spokenAudio
        case voicePrompt
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
extension AVAudioSession.Category {
    public init(_ category: _AVAudioSession.Category) {
        switch category {
            case .ambient:
                self = .ambient
            case .soloAmbient:
                self = .soloAmbient
            case .playback:
                self = .playback
            case .record:
                self = .record
            case .playAndRecord:
                self = .playAndRecord
            default:
                assertionFailure()
                
                self = .playback
        }
    }
}

extension AVAudioSession.Mode {
    public init(_ mode: _AVAudioSession.Mode) {
        switch mode {
            case .default:
                self = .default
            case .voiceChat:
                self = .voiceChat
            case .gameChat:
                self = .gameChat
            case .videoRecording:
                self = .videoChat
            case .measurement:
                self = .measurement
            case .moviePlayback:
                self = .moviePlayback
            case .videoChat:
                self = .videoChat
            case .spokenAudio:
                self = .spokenAudio
            case .voicePrompt:
                self = .voicePrompt
        }
    }
}
#endif
