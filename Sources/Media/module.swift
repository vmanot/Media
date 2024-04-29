//
// Copyright (c) Vatsal Manot
//

@_exported import Diagnostics
@_exported import Foundation
@_exported import Swallow

public enum _module {
    public static func initialize() {
        _ = HLSAssetDownloadManager.shared
    }
}
