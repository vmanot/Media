//
//  AnyMediaFile.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import CorePersistence

public struct AnyMediaFile: Identifiable {
    public let id: AnyHashable
    private let _file: any MediaFile
    
    public var file: any MediaFile { _file }
    
    public init(_ file: any MediaFile) {
        self.id = AnyHashable(_erasing: file.id)
        self._file = file
    }
    
    // Type casting helper
    public func cast<T: MediaFile>(to type: T.Type) -> T? {
        _file as? T
    }
    
    // Type checking helper
    public func isType<T: MediaFile>(of type: T.Type) -> Bool {
        _file is T
    }
}

// Add convenient properties for common types
public extension AnyMediaFile {
    var audioFile: AudioFile? {
        cast(to: AudioFile.self)
    }
    
    var videoFile: VideoFile? {
        cast(to: VideoFile.self)
    }
    
    var imageFile: ImageFile? {
        cast(to: ImageFile.self)
    }
}
