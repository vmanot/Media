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

    public init(
        _ data: Data,
        fileTypeHint: String? = nil
    ) {
        self = .data(data, fileTypeHint: fileTypeHint)
    }

    public var fileTypeHint: String? {
        switch self {
            case .data(_, let fileTypeHint):
                return fileTypeHint
            case .url(let url):
                return url.pathExtension.nilIfEmpty()
        }
    }
    
    public init(_ url: URL) {
        self = .url(url)
    }

    public func data() throws -> Data {
        switch self {
            case .data(let data, _):
                return data
            case .url(let url):
                return try .init(contentsOf: url)
        }
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
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
#endif
