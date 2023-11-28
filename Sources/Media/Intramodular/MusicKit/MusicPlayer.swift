//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)

import AVFoundation
import Combine
import MediaPlayer
import Swift

@_spi(Internal)
public final class MusicPlayer: ObservableObject {
    public static let system = MusicPlayer(base: .systemMusicPlayer)
    
    private let base: MPMusicPlayerController
    
    public var nowPlayingItem: MPMediaItem? {
        base.nowPlayingItem
    }
    
    public init(base: MPMusicPlayerController) {
        self.base = base
        
        base.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackQueueDidChange),
            name: NSNotification.Name.MPMusicPlayerControllerQueueDidChange,
            object: MPMusicPlayerController.systemMusicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackNowPlayingItemDidChange),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: MPMusicPlayerController.systemMusicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateDidChange),
            name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: MPMusicPlayerController.systemMusicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackVolumeDidChange),
            name: NSNotification.Name.MPMusicPlayerControllerVolumeDidChange,
            object: MPMusicPlayerController.systemMusicPlayer
        )
    }
    
    @objc
    private func playbackQueueDidChange() {
        objectWillChange.send()
    }
    
    @objc
    private func playbackNowPlayingItemDidChange() {
        objectWillChange.send()
    }
    
    @objc
    private func playbackStateDidChange() {
        objectWillChange.send()
    }
    
    @objc
    private func playbackVolumeDidChange() {
        objectWillChange.send()
    }
    
    deinit {
        base.endGeneratingPlaybackNotifications()
    }
}

#endif
