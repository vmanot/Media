//
// Copyright (c) Vatsal Manot
//

#if canImport(AVFoundation)

import AVFoundation
import Swallow

class _AVAudioPlayer: NSObject, AVAudioPlayerDelegate {
    let asset: MediaAssetLocation
    var volume: Double? {
        didSet {
            if let volume {
                self.player?.volume = Float(volume)
            }
        }
    }
    var completion: ((Result<Void, Error>) -> Void)?
    var player: AVAudioPlayer?
    
    var isPlaying: Bool {
        player?.isPlaying == true
    }
    
    init(
        asset: MediaAssetLocation,
        volume: Double?
    ) {
        self.asset = asset
        self.volume = volume
    }
    
    func play(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.completion = completion
        
        do {
            let player = try AVAudioPlayer(from: asset)
            
            if let assetURL = asset.url {
                try _tryAssert(FileManager.default.fileExists(at: assetURL))
            }
            
            player.delegate = self
            
            if let volume {
                player.volume = Float(volume)
            }
            
            if !player.prepareToPlay() {
                try _AVAudioSession.shared.setCategory(.playback, mode: .default)
                try _AVAudioSession.shared.setActive(true)
                
                if !player.prepareToPlay() {
                    runtimeIssue("Failed to prepare \(player) for playing audio.")
                }
            }

            player.play()
            
            self.player = player
        } catch {
            completion(.failure(error))
            
            tearDown()
        }
    }
    
    func stop() {
        player?.stop()
        
        tearDown()
    }
    
    func tearDown() {
        player = nil
        completion = { _ in }
    }
    
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        guard let completion else {
            assertionFailure()
            
            return
        }
        
        if flag {
            completion(.success(()))
        } else {
            completion(.failure(AVError(.unknown)))
        }
        
        tearDown()
    }
    
    func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        guard let completion else {
            assertionFailure()
            
            return
        }
        
        if let error {
            completion(.failure(error))
        } else {
            completion(.failure(AVError(.unknown)))
        }
        
        tearDown()
    }
}

#endif
