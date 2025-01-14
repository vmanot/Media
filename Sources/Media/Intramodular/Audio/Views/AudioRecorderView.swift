//
//  AudioRecorderView.swift
//  Media
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import SwiftUIX
import Speech
import AVFoundation

public struct AudioRecorderViewConfiguration: Hashable, Initiable, MergeOperatable {
    public var enableSpeechRecognition: Bool
    public var locale: Locale
    
    public init() {
        self.enableSpeechRecognition = true
        self.locale = .current
    }
    
    public init(enableSpeechRecognition: Bool = true, locale: Locale = .current) {
        self.enableSpeechRecognition = enableSpeechRecognition
        self.locale = locale
    }
    
    public mutating func mergeInPlace(with other: AudioRecorderViewConfiguration) {
        self.enableSpeechRecognition = other.enableSpeechRecognition
    }
}

public struct AudioRecorderView<Content: View>: View {
    let configuration: AudioRecorderViewConfiguration
    
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var speechRecognizer: SpeechRecognizer
    @State private var recordedAudio: AudioFile?
    @State private var currentAmplitudes: [CGFloat] = Array(repeating: 0, count: 30)
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    
    private let content: (AudioFile?) -> Content
    private let onRecord: ((AudioFile) -> Void)?
    
    public init(
        configuration: AudioRecorderViewConfiguration = AudioRecorderViewConfiguration(),
        onRecord: ((AudioFile) -> Void)? = nil,
        @ViewBuilder content: @escaping (AudioFile?) -> Content
    ) {
        self.configuration = configuration
        self.onRecord = onRecord
        self.content = content
        _speechRecognizer = StateObject(wrappedValue: SpeechRecognizer(
            enabled: configuration.enableSpeechRecognition,
            locale: configuration.locale
        ))
    }
    
    public var body: some View {
        VStack {
            DefaultAudioRecoderView(
                isRecording: recorder.state == .recording,
                recordingTime: recordingTime,
                transcribedText: speechRecognizer.transcribedText,
                amplitudes: currentAmplitudes,
                onRecordToggle: toggleRecording
            )
            .padding(.horizontal)
            
            content(recordedAudio)
        }
        .onChange(of: recorder.state) { state in
            if state == .finished {
                handleRecordingFinished()
            }
        }
    }
    
    private func toggleRecording() {
        Task {
            switch recorder.state {
                case .recording, .paused:
                    await stopRecording()
                default:
                    await startRecording()
            }
        }
    }
    
    private func startRecording() async {
        do {
            try await recorder.prepare()
            if configuration.enableSpeechRecognition {
                speechRecognizer.startRecognition()
            }
            try await recorder.record()
            startTimer()
        } catch {
            print("Recording error: \(error)")
        }
    }
    
    private func stopRecording() async {
        do {
            if configuration.enableSpeechRecognition {
                speechRecognizer.stopRecognition()
            }
            try await recorder.stop()
            stopTimer()
        } catch {
            print("Stop recording error: \(error)")
        }
    }
    
    private func handleRecordingFinished() {
        Task {
            if let data = try? recorder.recording?.data(),
               var audioFile = try? await AudioFile(
                data: data,
                name: UUID().uuidString,
                id: .random(),
                fileType: .m4a
               ) {
                audioFile.transcription = speechRecognizer.transcribedText
                recordedAudio = audioFile
                onRecord?(audioFile)
            }
        }
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateAmplitudes()
            if recordingTimer?.timeInterval == 0.1 {
                recordingTime += 0.1
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
        currentAmplitudes = Array(repeating: 0, count: 30)
    }
    
    private func updateAmplitudes() {
        currentAmplitudes.removeFirst()
        currentAmplitudes.append(CGFloat(recorder.normalizedPowerLevel))
    }
}
