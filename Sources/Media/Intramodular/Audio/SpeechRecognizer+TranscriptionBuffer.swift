//
//  SpeechRecognizer+TranscriptionBuffer.swift
//  Media
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import Speech

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
