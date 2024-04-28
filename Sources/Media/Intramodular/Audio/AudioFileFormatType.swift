//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import CorePersistence
import Swift

public enum AudioFileFormatType: String, CaseIterable, Hashable, Sendable {
    case aac = "aac"
    case aiff = "aiff"
    case alac = "alac"
    case flac = "flac"
    case mp3 = "mp3"
    case m4a = "m4a"
    case wav = "wav"
    case caf = "caf"
    case opus = "opus"
}

extension AudioFileFormatType {
    public var fileExtension: String {
        return rawValue
    }
}

extension AudioFileFormatType {
    var mimeType: String {
        switch self {
            case .aac:
                return "audio/aac"
            case .aiff:
                return "audio/aiff"
            case .alac:
                return "audio/alac"
            case .flac:
                return "audio/flac"
            case .mp3:
                return "audio/mpeg"
            case .m4a:
                return "audio/mp4"
            case .wav:
                return "audio/wav"
            case .caf:
                return "audio/x-caf"
            case .opus:
                return "audio/opus"
        }
    }
    
    init?(mimeType: String) {
        switch mimeType {
            case "audio/aac":
                self = .aac
            case "audio/aiff":
                self = .aiff
            case "audio/alac":
                self = .alac
            case "audio/flac":
                self = .flac
            case "audio/mpeg":
                self = .mp3
            case "audio/mp4":
                self = .m4a
            case "audio/wav":
                self = .wav
            case "audio/x-caf":
                self = .caf
            case "audio/opus":
                self = .opus
            default:
                return nil
        }
    }
}

extension AudioFileFormatType {
    func _toAVFileType() throws -> AVFileType {
        switch self {
            case .aac:
                throw Never.Reason.unsupported
            case .aiff:
                return .aiff
            case .alac:
                throw Never.Reason.unsupported
            case .flac:
                throw Never.Reason.unsupported
            case .mp3:
                return .mp3
            case .m4a:
                return .m4a
            case .wav:
                return .wav
            case .caf:
                return .caf
            case .opus:
                throw Never.Reason.unsupported
        }
    }
}

// MARK: - Supplementary

extension MediaAssetLocation {
    public func convert(
        to type: AudioFileFormatType,
        outputURL: URL? = nil
    ) async throws -> URL {
        let outputURL = outputURL ?? URL.temporaryDirectory
            .appending(.directory("com.vmanot.Media"))
            .appending(UUID().uuidString)
            .appendingPathExtension(type.fileExtension)
        
        _ = try? FileManager.default.createDirectoryIfNecessary(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let asset = AVAsset(url: try self._urlByWritingToTemporaryURLIfNeeded())
        
        try await asset.convert(to: type, outputURL: outputURL)
        
        return outputURL
    }
}
