//
// Copyright (c) Vatsal Manot
//

import Combine
import AVFoundation
import Swallow
import SwiftUIX

public class _BuiltinSpeechManager: ObservableObject {
    lazy var languageCodes = AVSpeechSynthesisVoice.speechVoices().map({
        $0.language
    })
    
    func displayName(
        for languageCode: String,
        locale: NSLocale = (Locale.autoupdatingCurrent as NSLocale)
    ) -> String? {
        locale.displayName(forKey: NSLocale.Key.identifier, value: languageCode)
    }
}

public class _BuiltinSpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    
    fileprivate override init() {
        
    }
    
    public func speak(
        _ u: _BuiltinSpeechUtterance
    ) {
        let utterance = AVSpeechUtterance(string: u.string)
        
        utterance.rate =?? utterance.rate
        utterance.pitchMultiplier =?? u.pitch
        utterance.voice = AVSpeechSynthesisVoice(language: u.language)!
        
        return synthesizer.speak(utterance)
    }
    
    public func speak(
        _ string: String
    ) {
        self.speak(.init(string: string))
    }
}
