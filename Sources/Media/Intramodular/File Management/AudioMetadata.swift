//
//  AudioMetadata.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI

public struct AudioMetadata: MediaMetadata {
    public var voiceID: String?
    
    public init(voiceID: String? = nil) {
        self.voiceID = voiceID
    }
}
