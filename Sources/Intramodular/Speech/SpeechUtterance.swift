//
// Copyright (c) Vatsal Manot
//

import SwiftUI

public struct SpeechUtterance: Codable, Hashable {
    public let rate: Float
    public let pitch: Float
    public let language: String
    public let volume: Float
    public let string: String
}
