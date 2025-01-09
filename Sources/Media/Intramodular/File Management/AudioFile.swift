//
//  AudioFile.swift
//  Voice
//
//  Created by Jared Davidson on 10/31/24.
//

import SwiftUI
import CorePersistence
import AVFoundation

public struct AudioFile: Identifiable, Hashable, Sendable {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    public let id: ID
    public let url: URL
    public let name: String
    public let size: Double
    public let duration: TimeInterval
    public var voiceID: String? = nil
    
    public var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var sizeFormatted: String {
        String(format: "%.1f MB", size)
    }
    
    public var estimatedCredits: Int {
        let creditsPerSecond = 1000.0 / 60.0
        let totalCredits = ceil(duration * creditsPerSecond)
        return Int(totalCredits)
    }
    
    // Initializers
    public init(
        id: ID = ID(),
        url: URL,
        name: String,
        size: Double,
        duration: TimeInterval,
        voiceID: String? = nil
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.duration = duration
        self.voiceID = voiceID
    }
    
    public init(
        data: Data,
        name: String,
        id: ID
    ) async throws {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.rawValue.uuidString)
            .appendingPathExtension(".m4a")
        
        try data.write(to: temporaryURL)
        try await self.init(
            url: temporaryURL
        )
    }
    
    public init(
        url: URL
    ) async throws {
        let asset = AVURLAsset(url: url,
                               options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        let isPlayable: Bool = try await asset.load(.isPlayable)
        
        guard isPlayable else {
            throw NSError(domain: "AudioFileError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Audio file is not playable"
            ])
        }
        
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Double(resourceValues.fileSize ?? 0) / (1024 * 1024)
        
        let duration = try await asset.load(.duration).seconds
        
        let fileName = url.lastPathComponent
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: permanentURL.path) {
            try FileManager.default.removeItem(at: permanentURL)
        }
        try FileManager.default.copyItem(at: url, to: permanentURL)
        
        self.id = .random()
        self.url = permanentURL
        self.name = permanentURL.lastPathComponent
        self.size = fileSize
        self.duration = duration
    }
    
    public func deleteFile() throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioFileError.fileNotFound
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw AudioFileError.failedToDeleteFile
        }
    }
}

// MARK: - Conformances

extension AudioFile: Codable {
    enum CodingKeys: CodingKey {
        case id
        case url
        case name
        case size
        case duration
        case voiceID
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(AudioFile.ID.self, forKey: .id)
        self.url = try container.decode(URL.self, forKey: .url)
        self.name = try container.decode(String.self, forKey: .name)
        self.size = try container.decode(Double.self, forKey: .size)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.voiceID = try container.decodeIfPresent(String.self, forKey: .voiceID)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.size, forKey: .size)
        try container.encode(self.duration, forKey: .duration)
        try container.encode(self.voiceID, forKey: .voiceID)
    }
}

extension AudioFile: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension AudioFile: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .audio)
        
        FileRepresentation(contentType: .audio) { audioFile in
            SentTransferredFile(audioFile.url)
        } importing: { received in
            let url = received.file
            return try await AudioFile(url: url)
        }
        
        ProxyRepresentation(exporting: \.url)
        
        DataRepresentation(contentType: .audio) { audioFile in
            try Data(contentsOf: audioFile.url)
        } importing: { data in
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("audio")
            
            try data.write(to: temporaryURL)
            return try await AudioFile(url: temporaryURL)
        }
    }
}

// Error Handling

public enum AudioFileError: Error {
    case invalidURL
    case failedToGetFileSize
    case failedToLoadAudioFile
    case audioNotPlayable
    case unsupportedFileFormat
    case failedToDeleteFile
    case fileNotFound
}
