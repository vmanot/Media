//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import Swift

#if os(iOS) || os(tvOS) || os(visionOS)
public struct _AVAudioSession {
    private let base: AVAudioSession
    
    public static var shared: Self {
        .init(base: .sharedInstance())
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
