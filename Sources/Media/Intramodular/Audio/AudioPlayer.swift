//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)

import AVFoundation
import Foundation
import Swallow

public final class AudioPlayer {
    private var shouldDeactivateAudioSession = true
    private var didSetUp = false
    
    public init() {
        _ = try? setUp()
    }
    
    private func setUp() throws {
        if didSetUp {
            return
        }
        
        defer {
            didSetUp = true
        }
        
        let audioSession = _AVAudioSession.shared
        
        _expectNoThrow {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        }
        
        shouldDeactivateAudioSession = true
    }
    
    private func tearDown() throws {
        guard shouldDeactivateAudioSession else {
            return
        }
        
        try _AVAudioSession.shared.setActive(false)
    }
    
    deinit {
        _ = try? tearDown()
    }
    
    public func play(
        _ asset: MediaAssetLocation
    ) async throws {
        let player = _AVAudioPlayer(asset: asset, volume: 1.0)
        
        try await withCheckedThrowingContinuation { continuation in
            player.play { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension AudioPlayer {
    public func play(
        _ url: URL
    ) async throws {
        try await play(.url(url))
    }
    
    public func play(
        _ data: Data,
        fileTypeHint: String?
    ) async throws {
        try await play(.data(data, fileTypeHint: fileTypeHint))
    }
}

#endif
