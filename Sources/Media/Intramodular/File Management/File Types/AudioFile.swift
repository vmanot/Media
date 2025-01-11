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
    }
    
    public init(
        data: Data,
        name: String,
        id: ID,
        metadata: [String : AnyCodable] = [:]
    ) async throws {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.rawValue.uuidString)
            .appendingPathExtension(".mp3")
        print(temporaryURL)
        try data.write(to: temporaryURL)
        try await self.init(
            url: temporaryURL
        )
    }
    
    public init(
        url: URL
    ) async throws {
        print(url)
        let asset = AVURLAsset(url: url,
                              options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        let isPlayable: Bool = try await asset.load(.isPlayable)
        
        guard isPlayable else {
            throw AudioFileError.audioNotPlayable
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
        self.metadata = [:]
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
