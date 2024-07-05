//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUI
import UniformTypeIdentifiers

public enum _ImageFormatType: CaseIterable {
    case gif
    case jpeg
    case png
    case heic
    case webp
    
    var _mediaAssetFileType: _MediaAssetFileType {
        switch self {
            case .gif:
                return .gif
            case .jpeg:
                return .jpeg
            case .png:
                return .png
            case .heic:
                return .heic
            case .webp:
                return .webp
        }
    }
}

extension _ImageFormatType {
    public var mimeType: String {
        _mediaAssetFileType.mimeType
    }
    
    public var uniformTypeIdentifier: UTType {
        _mediaAssetFileType.utType
    }
}
