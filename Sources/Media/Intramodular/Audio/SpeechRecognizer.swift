//
//  SpeechRecognizer.swift
//  Media
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import Speech
import AVFoundation
import SwiftUIX

class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcribedText = ""
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let transcriptionBuffer = TranscriptionBuffer()
    private let recognizer: SFSpeechRecognizer
    private var audioEngine: AVAudioEngine?
    
    init(locale: Locale) {
        self.recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: .current)!
        super.init()
        
        #if os(iOS)
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                print("Speech recognition not authorized")
                return
            }
            self?.recognizer.delegate = self
        }
        #else
        self.recognizer.delegate = self
        #endif
    }
    
    func startRecognition() {
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        recognitionRequest.requiresOnDeviceRecognition = false
        
        do {
            try _AVAudioSession.shared.setCategory(.playAndRecord, mode: .default)
            try _AVAudioSession.shared.setActive(true)
            
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            engine.prepare()
            try engine.start()
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Recognition error: \(error)")
                    return
                }
                
                if let result = result {
                    let newTranscription = result.bestTranscription.formattedString
                    let processedText = self.transcriptionBuffer.processNewTranscription(newTranscription)
                    
                    DispatchQueue.main.async {
                        self.transcribedText = processedText
                    }
                    
                    if result.isFinal {
                        self.transcriptionBuffer.reset()
                    }
                }
            }
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func stopRecognition() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }
}

// MARK: - Conformances

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("Speech recognition became unavailable")
        }
    }
}
