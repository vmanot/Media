//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public enum _ImageFormatType: CaseIterable {
    case gif
    case jpeg
    case png
    case heic
    case webp
    
    public var mimeType: String {
        switch self {
            case .gif:
                return "image/gif"
            case .jpeg:
                return "image/jpeg"
            case .png:
                return "image/png"
            case .heic:
                return "image/heic"
            case .webp:
                return "image/webp"
        }
    }
    
    /// The uniform type identifier for the image type.
    public var uniformTypeIdentifier: UTType {
        switch self {
            case .gif:
                return UTType("com.compuserve.gif")!
            case .jpeg:
                return UTType("public.jpeg")!
            case .png:
                return UTType("public.png")!
            case .heic:
                return UTType("public.heic")!
            case .webp:
                return UTType("public.webp")!
        }
    }
}
