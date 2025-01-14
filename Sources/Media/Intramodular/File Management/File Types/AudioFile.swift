//
//  AudioFile.swift
//  Voice
//
//  Created by Jared Davidson on 10/31/24.
//

import SwiftUI
import CorePersistence
import AVFoundation
import CoreTransferable

public struct AudioFile: MediaFile {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    public let id: ID
    public let url: URL
    public let name: String
    public let size: Double
    public let duration: TimeInterval
    public var metadata: [String : AnyCodable]
    public var transcription: String?
    public var asset: AVURLAsset
    
    public var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var sizeFormatted: String {
        String(format: "%.1f MB", size)
    }
    
    // This is too niche I believe as it's strictly AI related
    public var estimatedCredits: Int {
        let creditsPerSecond = 1000.0 / 60.0
        let totalCredits = ceil(duration * creditsPerSecond)
        return Int(totalCredits)
    }
    
    public init(
        url: URL,
        name: String,
        size: Double,
        duration: TimeInterval,
        metadata: [String : AnyCodable] = [:]
    ) {
        self.id = .random()
        self.url = url
        self.name = name
        self.size = size
        self.duration = duration
        self.metadata = metadata
        self.asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        /*
        let isPlayable: Bool = try await asset.load(.isPlayable)
        
        guard isPlayable else {
            throw AudioFileError.audioNotPlayable
        }
        */
    }
    
    public init(
        data: Data,
        name: String,
        id: ID,
        fileType: AudioFileFormatType = .mp3,
        metadata: [String : AnyCodable] = [:]
    ) async throws {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.rawValue.uuidString)
            .appendingPathExtension(fileType.fileExtension)
        
        try data.write(to: temporaryURL)
        try await self.init(
            url: temporaryURL
        )
    }
    
    public init(
        id: ID = .random(),
        data: Data,
        name: String,
        destinationURL: URL,
        metadata: [String: AnyCodable] = [:]
    ) async throws {
        try data.write(to: destinationURL)
        try await self.init(url: destinationURL, metadata: metadata)
    }
    
    public init(url: URL) async throws {
        try await self.init(url: url, metadata: [:])
    }
    
    public init(
        url: URL,
        metadata: [String: AnyCodable] = [:]
    ) async throws {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        let isPlayable: Bool = try await asset.load(.isPlayable)
        
        guard isPlayable else {
            throw AudioFileError.audioNotPlayable
        }
        
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Double(resourceValues.fileSize ?? 0) / (1024 * 1024)
        let duration = try await asset.load(.duration).seconds
        
        self.id = .random()
        self.url = url
        self.name = url.lastPathComponent
        self.size = fileSize
        self.duration = duration
        self.metadata = metadata
        self.asset = asset
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
    public enum CodingKeys: String, CodingKey {
        case id
        case url
        case name
        case size
        case duration
        case metadata
    }
    
    public init(from decoder: any Decoder) throws {
        self.id = try decoder.decode(forKey: CodingKeys.id)
        self.url = try decoder.decode(URL.self, forKey: CodingKeys.url)
        self.name = try decoder.decode(String.self, forKey: CodingKeys.name)
        self.size = try decoder.decode(Double.self, forKey: CodingKeys.size)
        self.duration = try decoder.decode(TimeInterval.self, forKey: CodingKeys.duration)
        self.metadata = try decoder.decode([String: AnyCodable].self, forKey: CodingKeys.metadata)
        self.asset = AVURLAsset(url: self.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
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
