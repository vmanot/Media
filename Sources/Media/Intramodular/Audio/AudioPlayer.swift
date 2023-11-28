//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)

import AVFoundation
import Combine
import Foundation
import Swallow
import SwiftUI

/// A sane, modern replacement for `AVAudioPlayer`.
public final class AudioPlayer: NSObject, ObservableObject {
    private var _base: AVAudioPlayer?
    #if os(iOS) || os(tvOS) || os(visionOS)
    private var session: AVAudioSession = .sharedInstance()
    #endif
    
    public var base: AVAudioPlayer {
        get throws {
            try _base.unwrap()
        }
    }
    
    public var _source: MediaAssetLocation?
    
    public var isPlaying: Bool {
        (try? base.isPlaying) ?? false
    }
}

extension AudioPlayer {
    public func prepare() throws {
        guard let source = _source else {
            return
        }
        
        switch source {
            case .url(let url):
                _base = try AVAudioPlayer(contentsOf: url)
            case .data(let data):
                _base = try AVAudioPlayer(data: data)
        }
        
        try base.delegate = self
    }
    
    public func play() throws {
        try base.play()
    }
    
    public func pause() throws {
        try base.pause()
    }
    
    public func stop() throws {
        try base.stop()
        
        _base = nil
        _source = nil
    }
    
    public func toggle() throws {
        if isPlaying {
            try pause()
        } else {
            try play()
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        objectWillChange.send()
    }
    
    public func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        objectWillChange.send()
    }
    
    public func audioPlayerBeginInterruption(
        _ player: AVAudioPlayer
    ) {
        objectWillChange.send()
    }
    
    public func audioPlayerEndInterruption(
        _ player: AVAudioPlayer,
        withOptions flags: Int
    ) {
        objectWillChange.send()
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
extension AudioPlayer {
    func _configureSharedAudioSessionIfAvailable() {
        _expectNoThrow {
            try session.setCategory(.playback, options: .defaultToSpeaker)
            try session.setActive(true, options: [])
        }
    }
}
#else
extension AudioPlayer {
    func _configureSharedAudioSessionIfAvailable() {
        // fuck you macOS
    }
}
#endif

#endif
