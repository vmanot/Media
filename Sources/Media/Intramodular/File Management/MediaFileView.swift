//
//  MediaFileView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import AVFoundation

public struct MediaFileView: View {
    let file: any MediaFile
    @StateObject private var player = AudioPlayer()
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var videoPlayer: AVPlayer?
    
    public init(file: any MediaFile) {
        self.file = file
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and size
            HStack {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(file.sizeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Media content
            if let audioFile = file as? AudioFile {
                audioPlayerView(for: audioFile)
            } else if let videoFile = file as? VideoFile {
                videoPlayerView(for: videoFile)
            }
            
            // Footer with duration
            HStack {
                Label("\(file.durationFormatted)", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let videoFile = file as? VideoFile {
                    Spacer()
                    
                    Label(videoFile.resolution.description, systemImage: "rectangle.badge.checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private func audioPlayerView(for file: AudioFile) -> some View {
        HStack(spacing: 16) {
            Button {
                Task {
                    if isPlaying {
                        player.stop()
                    } else {
                        try await player.play(file.url)
                    }
                    isPlaying.toggle()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Slider(value: $currentTime, in: 0...file.duration)
                    .disabled(true) // Until we implement seeking
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption2)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(file.durationFormatted)
                        .font(.caption2)
                        .monospacedDigit()
                }
            }
        }
    }
    
    @ViewBuilder
    private func videoPlayerView(for file: VideoFile) -> some View {
        VideoPlayer(player: videoPlayer)
            .aspectRatio(file.resolution.aspectRatio, contentMode: .fit)
            .frame(maxHeight: 300)
            .onAppear {
                videoPlayer = AVPlayer(url: file.url)
            }
            .onDisappear {
                videoPlayer?.pause()
                videoPlayer = nil
            }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
