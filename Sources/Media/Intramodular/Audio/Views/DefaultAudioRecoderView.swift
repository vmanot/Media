//
//  DefaultAudioRecoderView.swift
//  Media
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import Speech

public struct DefaultAudioRecoderView: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let transcribedText: String
    let amplitudes: [CGFloat]
    public let onRecordToggle: () -> Void
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemGray6)
            
            VStack(spacing: 16) {
                if isRecording {
                    HStack(spacing: 2) {
                        ForEach(amplitudes.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.accentColor)
                                .frame(width: 3, height: max(3, amplitudes[index] * 50))
                                .animation(.linear(duration: 0.1), value: amplitudes[index])
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                }
                
                VStack(spacing: 8) {
                    recordButton
                    
                    if isRecording {
                        Text(timeString(from: recordingTime))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !transcribedText.isEmpty {
                    Text(transcribedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var recordButton: some View {
        #if os(iOS)
        Button(action: onRecordToggle) {
            Circle()
                .fill(isRecording ? Color.red : Color.accentColor)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .foregroundStyle(.white)
                }
        }
        #else
        Button(action: onRecordToggle) {
            Circle()
                .fill(isRecording ? Color.red : Color.accentColor)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.borderless)
        .focusable(false)
        .help(isRecording ? "Stop Recording" : "Start Recording")
        #endif
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
