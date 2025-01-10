//
//  AnyMediaFile.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import CorePersistence

public struct AnyMediaFile: Identifiable {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    public let id: ID
    private let _file: any MediaFile
    
    public var file: any MediaFile { _file }
    
    public init(_ file: any MediaFile) {
        self.id = .random()
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

// MARK: - Conformances

extension AnyMediaFile: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case file
    }
    
    private enum MediaType: String, Codable {
        case audio
        case video
        case image
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        // Encode type information
        switch _file {
        case is AudioFile:
            try container.encode(MediaType.audio, forKey: .type)
        case is VideoFile:
            try container.encode(MediaType.video, forKey: .type)
        case is ImageFile:
            try container.encode(MediaType.image, forKey: .type)
        default:
            throw EncodingError.invalidValue(_file, EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported media file type"
            ))
        }
        
        // Encode the file itself
        try container.encode(_file, forKey: .file)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(ID.self, forKey: .id)
        
        // Decode type information
        let mediaType = try container.decode(MediaType.self, forKey: .type)
        
        // Decode the specific type based on the type information
        switch mediaType {
        case .audio:
            let audioFile = try container.decode(AudioFile.self, forKey: .file)
            self._file = audioFile
        case .video:
            let videoFile = try container.decode(VideoFile.self, forKey: .file)
            self._file = videoFile
        case .image:
            let imageFile = try container.decode(ImageFile.self, forKey: .file)
            self._file = imageFile
        }
    }
}

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
