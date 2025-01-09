//
// Copyright (c) Preternatural AI, Inc.
//

import AVFoundation
import CorePersistence
import Foundation

public struct VideoFile: Identifiable, Hashable {
    public typealias ID = _TypeAssociatedID<Self, UUID>

    public let id: ID
    public let url: URL
    public let name: String
    public let size: Double
    public let duration: TimeInterval
    public let resolution: VideoFile.Resolution
    public let modelID: String?
    
    public var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var sizeFormatted: String {
        String(format: "%.1f MB", size)
    }
    
    public init(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let track = tracks.first else {
            throw VideoFileError.noVideoTrack
        }
        
        let dimensions = try await track.load(.naturalSize)
        let duration = try await asset.load(.duration).seconds
        let resources = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Double(resources.fileSize ?? 0) / (1024 * 1024)
        
        self.id = .random()
        self.url = url
        self.name = url.lastPathComponent
        self.size = fileSize
        self.duration = duration
        self.resolution = .detectResolution(
            width: Int(dimensions.width),
            height: Int(dimensions.height)
        )
        self.modelID = nil
    }
}

extension VideoFile: Codable {
    
}

// Error Handling

public enum VideoFileError: LocalizedError {
    case invalidURL
    case noVideoTrack
    case failedToGetFileSize
    case failedToLoadVideo
    case unsupportedFormat
    case failedToDeleteFile
    case fileNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .noVideoTrack:
            return "No video track found in file"
        case .failedToGetFileSize:
            return "Failed to get video file size"
        case .failedToLoadVideo:
            return "Failed to load video"
        case .unsupportedFormat:
            return "Unsupported video format"
        case .failedToDeleteFile:
            return "Failed to delete video file"
        case .fileNotFound:
            return "Video file not found"
        }
    }
}
