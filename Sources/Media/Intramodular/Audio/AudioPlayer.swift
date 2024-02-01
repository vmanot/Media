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
    
    private var shouldDeactivateAudioSession = true
    private var didSetUp = false
    private var players: [_AVAudioPlayer] = []
    
    public var isPlaying: Bool {
        players.contains(where: \.isPlaying)
    }
    
    public var volume: Double? {
        didSet {
            if let volume {
                players.forEach({ $0.volume = volume  })
            }
        }
    }
    
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
        let player = _AVAudioPlayer(asset: asset, volume: self.volume)
        
        players.append(player)
        
        try await withCheckedThrowingContinuation { continuation in
            objectWillChange.withCriticalScope { objectWillChange in
                objectWillChange.send()

                player.play { result in
                    continuation.resume(with: result)
                }
            }
        }
        
        players.removeAll(where: { $0 === player })
    }
    
    public func stop() {
        players.forEach({ $0.stop() })
        players.removeAll()
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
