//
//  VideoFileCell.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

public struct VideoFileCell: View {
    let file: VideoFile
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var currentTime: TimeInterval = 0
    
    public init(file: VideoFile) {
        self.file = file
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                ZStack {
                    Color.black
                    
                    VideoPlayerView(file: file, geometry: geometry)
                }
                .onAppear {
                    setupPlayer()
                }
                .onDisappear {
                    teardownPlayer()
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
    
    private func setupPlayer() {
        let player = AVPlayer(url: file.url)
        self.player = player
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }
    
    private func teardownPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        currentTime = 0
    }
}

struct VideoPlayerView: View {
    let file: VideoFile
    let geometry: GeometryProxy
    
    var body: some View {
        let videoAspectRatio = Double(file.resolution.height) / Double(file.resolution.width)
        let containerAspectRatio = geometry.size.height / geometry.size.width
        
        if videoAspectRatio > containerAspectRatio {
            VideoPlayer(player: AVPlayer(url: file.url))
                .frame(
                    width: geometry.size.height / CGFloat(videoAspectRatio),
                    height: geometry.size.height
                )
        } else {
            VideoPlayer(player: AVPlayer(url: file.url))
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.width * CGFloat(videoAspectRatio)
                )
        }
    }
}
