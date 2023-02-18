//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || targetEnvironment(macCatalyst)

import AVFoundation
import Combine
import Foundation
import SwiftUI

public final class AudioPlayer: NSObject, ObservableObject {
    private var base: AVAudioPlayer?
    private var session: AVAudioSession = .sharedInstance()
    
    public var source: AssetLocation?
    
    public var isPlaying: Bool {
        base?.isPlaying ?? false
    }
}

extension AudioPlayer {
    public func prepare() throws {
        guard let source = source else {
            return
        }
        
        switch source {
            case .url(let url):
                base = try AVAudioPlayer(contentsOf: url)
            case .data(let data):
                base = try AVAudioPlayer(data: data)
        }
        
        base?.delegate = self
    }
    
    public func play() throws {
        try? session.setCategory(.playback, options: .defaultToSpeaker)
        try session.setActive(true, options: [])
        
        try base.unwrap().play()
    }
    
    public func pause() throws {
        try base.unwrap().pause()
    }
    
    public func stop() throws {
        try base.unwrap().stop()
        
        base = nil
        source = nil
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
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        objectWillChange.send()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        objectWillChange.send()
    }
    
    public func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        objectWillChange.send()
    }
    
    public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        objectWillChange.send()
    }
}

#endif
