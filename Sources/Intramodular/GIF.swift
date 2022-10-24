//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUI

/// A type that represents a GIF.
public struct GIF: Codable, Hashable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }
}

#if os(macOS)
extension GIF {
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

                try data.write(to: temporaryFileURL)

                pasteboard.declareTypes([.fileNameType(forPathExtension: "gif")], owner: nil)
                pasteboard.writeObjects([temporaryFileURL as NSURL])
            case .inlineData:
                let pasteboardType = NSPasteboard.PasteboardType(rawValue: ImageType.gif.uniformTypeIdentifier.identifier)

                pasteboard.declareTypes([pasteboardType], owner: nil)
                pasteboard.setData(data, forType: pasteboardType)
        }
    }
}
#endif
