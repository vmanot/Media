//
//  SpeechRecognizer+TranscriptionBuffer.swift
//  Media
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import Speech

// When I was building out AI Voice I noticed the built in transcription from AVSpeechRecognizer restarted any time I paused speaking in iOS 18
// While reading through some forums it sounds like this is a new bug, so this `Transcription Buffer` is used to make up for it so that no matter
// how much I pause speaking or delay, it will accumulate all the talking points into one single sentence.

class TranscriptionBuffer {
    private var lastProcessedText = ""
    private var currentBuffer = ""
    private var lastUpdateTime = Date()
    private let updateThreshold: TimeInterval = 0.5
    
    func processNewTranscription(_ newText: String) -> String {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        
        if timeSinceLastUpdate > updateThreshold {
            if !currentBuffer.isEmpty {
                lastProcessedText = currentBuffer
            }
            currentBuffer = newText
            lastUpdateTime = now
            return newText
        }
        
        if !newText.isEmpty && !isSubstantiallyDuplicate(newText) {
            currentBuffer = newText
            lastUpdateTime = now
            return newText
        }
        
        return currentBuffer
    }
    
    private func isSubstantiallyDuplicate(_ newText: String) -> Bool {
        let existingWords = currentBuffer.components(separatedBy: .whitespacesAndNewlines)
        let newWords = newText.components(separatedBy: .whitespacesAndNewlines)
        
        if newWords.count < existingWords.count {
            return true
        }
        
        let existingPhrase = existingWords.joined(separator: " ")
        let newPhrase = newWords.joined(separator: " ")
        
        let occurrences = newPhrase.components(separatedBy: existingPhrase).count - 1
        return occurrences > 1
    }
    
    func reset() {
        lastProcessedText = ""
        currentBuffer = ""
        lastUpdateTime = Date()
    }
}
