//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUI
import UniformTypeIdentifiers

public enum ImageFileFormatType: String, CaseIterable, Codable, Hashable, Sendable {
    case tiff
    case bmp
    case gif
    case jpeg
    case jpeg2000
    case png
    case heic
    case webp
    
    var _mediaAssetFileType: _MediaAssetFileType {
        switch self {
            case .tiff:
                return .tiff
            case .bmp:
                return .bmp
            case .gif:
                return .gif
            case .jpeg:
                return .jpeg
            case .jpeg2000:
                return .jpeg2000
            case .png:
                return .png
            case .heic:
                return .heic
            case .webp:
                return .webp
        }
    }
}

#if os(macOS)
extension ImageFileFormatType {
    public init(_ type: NSBitmapImageRep.FileType) {
        switch type {
            case .tiff:
                self = .tiff
            case .bmp:
                self = .bmp
            case .gif:
                self = .gif
            case .jpeg:
                self = .jpeg
            case .jpeg2000:
                self = .jpeg2000
            case .png:
                self = .png
            @unknown default:
                self = .png
        }
    }
}
#endif

extension ImageFileFormatType {
    public var mimeType: String {
        _mediaAssetFileType.mimeType
    }
    
    public var uniformTypeIdentifier: UTType {
        _mediaAssetFileType.utType
    }
    
    public var preferredFilenameExtension: String {
        uniformTypeIdentifier.preferredFilenameExtension ?? "png"
    }
}
