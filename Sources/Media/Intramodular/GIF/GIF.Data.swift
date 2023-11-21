//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUI

extension GIF {
    /// A type that represents a GIF.
    public struct Data: Codable, Hashable, RawRepresentable, Sendable {
        public typealias RawValue = Foundation.Data
        
        public let rawValue: RawValue
        
        public init?(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

#if os(macOS)
extension GIF.Data {
    /// The manner in which to copy the GIF contents to an `NSPasteboard`.
    private enum _PasteboardDumpStrategy {
        case localFileURL
        case inlineData
    }
    
    public func dump(
        into pasteboard: NSPasteboard,
        forPasteIn bundleID: Bundle.ID? = nil
    ) throws {
        let strategy: _PasteboardDumpStrategy
        
        switch bundleID {
            case "com.apple.MobileSMS":
                strategy = .localFileURL
            case "ru.keepcoder.Telegram":
                strategy = .localFileURL
            case "com.google.Chrome":
                strategy = .localFileURL
            default:
                strategy = .inlineData
        }
        
        switch strategy {
            case .localFileURL:
                let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".gif", conformingTo: .gif)
                
                try rawValue.write(to: temporaryFileURL)
                
                pasteboard.declareTypes([.fileNameType(forPathExtension: "gif")], owner: nil)
                pasteboard.writeObjects([temporaryFileURL as NSURL])
            case .inlineData:
                let pasteboardType = NSPasteboard.PasteboardType(rawValue: _ImageFormatType.gif.uniformTypeIdentifier.identifier)
                
                pasteboard.declareTypes([pasteboardType], owner: nil)
                pasteboard.setData(rawValue, forType: pasteboardType)
        }
    }
}
#endif
