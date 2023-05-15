//
// Copyright (c) Vatsal Manot
//

import Combine
import AVFoundation
import SwiftUIX

public class SpeechManager: ObservableObject {
    lazy var languageCodes = AVSpeechSynthesisVoice.speechVoices().map({ $0.language })
    
    func displayName(for languageCode: String) -> String? {
        (Locale.autoupdatingCurrent as NSLocale)
            .displayName(forKey: NSLocale.Key.identifier, value: languageCode)
    }
}

public class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    
    fileprivate override init() {
        
    }
    
    func speak(_ u: SpeechUtterance) {
        let utterance = AVSpeechUtterance(string: u.string)
        
        utterance.rate = utterance.rate
        utterance.pitchMultiplier = u.pitch
        utterance.voice = AVSpeechSynthesisVoice(language: u.language)!
        
        return synthesizer.speak(utterance)
    }
}
