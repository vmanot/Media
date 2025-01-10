//
//  AudioFileCell.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import AVFoundation

public struct AudioFileCell: View {
    let file: AudioFile
    @StateObject private var player = AudioPlayer()
    @State private var currentTime: TimeInterval = 0
    @State private var isSeeking: Bool = false
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public init(file: AudioFile) {
        self.file = file
    }
    
    public var body: some View {
        VStack {
            HStack(spacing: 16) {
                Button {
                    Task {
                        if player.isPlaying {
                            player.stop()
                        } else {
                            do {
                                try await player.play(file.url)
                            } catch {
                                print("Error playing audio: \(error)")
                            }
                        }
                    }
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $currentTime, in: 0...file.duration) { isEditing in
                        if isEditing {
                            isSeeking = true
                        } else {
                            isSeeking = false
                            if player.isPlaying {
                                player.seek(to: currentTime)
                            }
                        }
                    }
                    
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
            
            HStack {
                Label("\(file.durationFormatted)", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            if player.isPlaying && !isSeeking {
                currentTime = player.currentTime
                
                if currentTime >= file.duration {
                    player.stop()
                    currentTime = 0
                }
            }
        }
        .onDisappear {
            player.stop()
            currentTime = 0
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
