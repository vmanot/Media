//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

public enum MediaAssetLocation: Hashable {
    case data(Data)
    case url(URL)

    public init(_ data: Data) {
        self = .data(data)
    }

    public init(_ url: URL) {
        self = .url(url)
    }

    public func data() throws -> Data {
        switch self {
            case .data(let data):
                return data
            case .url(let url):
                return try .init(contentsOf: url)
        }
    }
}
