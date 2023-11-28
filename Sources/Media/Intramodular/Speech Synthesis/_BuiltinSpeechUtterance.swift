//
// Copyright (c) Vatsal Manot
//

import SwiftUI

public struct _BuiltinSpeechUtterance: Codable, Hashable, Sendable {
    public let rate: Float?
    public let pitch: Float?
    public let language: String?
    public let volume: Float?
    public let string: String
    
    public init(
        rate: Float? = nil,
        pitch: Float? = nil,
        language: String? = nil,
        volume: Float? = nil,
        string: String
    ) {
        self.rate = rate
        self.pitch = pitch
        self.language = language
        self.volume = volume
        self.string = string
    }
}
