//
// Copyright (c) Vatsal Manot
//

#if canImport(AVFoundation)
import AVFoundation
#endif
import Foundation
import Swift

public enum MediaAssetLocation: Hashable {
    case data(Data, fileTypeHint: String?)
    case url(URL)
    
    public var url: URL? {
        guard case .url(let result) = self else {
            return nil
        }
        
        return result
    }
    
    public init(
        _ data: Data,
        fileTypeHint: String? = nil
    ) {
        self = .data(data, fileTypeHint: fileTypeHint)
    }
    
    public init(_ url: URL) {
        self = .url(url)
    }
    
    public init(filePath: String) {
        self = .url(URL(fileURLWithPath: filePath))
    }
}

extension MediaAssetLocation {
    public var fileName: String? {
        switch self {
            case .data(_, _):
                return nil
            case .url(let url):
                return url.lastPathComponent
        }
    }
    
    public var fileTypeHint: String? {
        switch self {
            case .data(_, let fileTypeHint):
                return fileTypeHint
            case .url(let url):
                return url.pathExtension.nilIfEmpty()
        }
    }
    
    public func data() throws -> Data {
        switch self {
            case .data(let data, _):
                return data
            case .url(let url):
                return try .init(contentsOf: url)
        }
    }
    
    public func write(to url: URL) throws {
        let data = try self.data()
        
        try data.write(to: url)
    }
    
    public func _urlByWritingToTemporaryURLIfNeeded() throws -> URL {
        switch self {
            case .data(let data, _):
                let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
               
                try data.write(to: url)
                
                return url
            case .url(let url):
                return url
        }
    }
}

#if !targetEnvironment(simulator)
extension MediaAssetLocation {
    public static func temporaryForRecording() -> Self {
        .url(FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a"))
    }
}
#else
extension MediaAssetLocation {
    public static func temporaryForRecording() -> Self {
        .url(FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".caf"))
    }
}
#endif

// MARK: - Supplementary

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
extension AVPlayer {
    public convenience init(from location: MediaAssetLocation) throws {
        self.init(url: try location._urlByWritingToTemporaryURLIfNeeded())
    }
}

extension AVAudioPlayer {
    public convenience init(from location: MediaAssetLocation) throws {
        switch location {
            case .data(let data, let fileTypeHint):
                try self.init(data: data, fileTypeHint: fileTypeHint)
            case .url(let url):
                try self.init(contentsOf: url)
        }
    }
}

extension AVAudioRecorder {
    public convenience init(
        from location: MediaAssetLocation,
        settings: [String: Any] = [:]
    ) throws {
        try self.init(url: try location._urlByWritingToTemporaryURLIfNeeded(), settings: settings)
    }
}
#endif
