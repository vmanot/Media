//
// Copyright (c) Vatsal Manot
//

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
    
    func speak(_ utterance: SpeechUtterance) {
        synthesizer.speak(AVSpeechUtterance(string: utterance.string).then {
            $0.rate = utterance.rate
            $0.pitchMultiplier = utterance.pitch
            $0.voice = AVSpeechSynthesisVoice(language: utterance.language)!
        })
    }
}
