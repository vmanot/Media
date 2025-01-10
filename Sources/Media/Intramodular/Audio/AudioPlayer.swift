//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)

import AVFoundation
import Foundation
import Merge
import Swallow

public final class AudioPlayer: ObservableObject, @unchecked Sendable {
    public let objectWillChange = _AsyncObjectWillChangePublisher()
    
    private var currentPlayer: _AVAudioPlayer?
    
    public var isPlaying: Bool {
        currentPlayer?.isPlaying ?? false
    }
    
    public var volume: Double? {
        didSet {
            if let volume {
                currentPlayer?.volume = volume
            }
        }
    }
    
    public init() {
        
    }
    
    private func tearDown() throws {
        try _AVAudioSession.shared.setActive(false)
    }
    
    deinit {
        _ = try? tearDown()
    }
    
    public func play(_ asset: MediaAssetLocation) async throws {
        // Stop any existing playback
        stop()
        
        // Create new player
        let player = _AVAudioPlayer(asset: asset, volume: self.volume)
        currentPlayer = player
        
        // Play and wait for completion
        try await withCheckedThrowingContinuation { continuation in
            objectWillChange.withCriticalScope { objectWillChange in
                objectWillChange.send()
                player.play { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        // Clean up after completion
        currentPlayer = nil
    }
    
    public func stop() {
        currentPlayer?.stop()
        currentPlayer = nil
    }
    
    public var currentTime: TimeInterval {
        currentPlayer?.player?.currentTime ?? 0
    }
    
    public func seek(to time: TimeInterval) {
        currentPlayer?.player?.currentTime = time
    }
}

extension AudioPlayer {
    public func play(_ url: URL) async throws {
        let audioSession = _AVAudioSession.shared
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        try await play(.url(url))
    }
    
    public func play(
        _ data: Data,
        fileTypeHint: String?
    ) async throws {
        let audioSession = _AVAudioSession.shared
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        try await play(.data(data, fileTypeHint: fileTypeHint))
    }
}

#endif
