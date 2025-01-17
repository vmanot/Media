//
//  FileDropView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import Foundation
import Swallow
import UniformTypeIdentifiers

public protocol MediaMetadata: Codable, Hashable {}

public protocol MediaFile: Identifiable, Codable, Hashable, Sendable {
    var id: ID { get }
    var url: URL { get }
    var name: String { get }
    var size: Double { get }
    var sizeFormatted: String { get }
    var metadata: [String: AnyCodable] { get set }
    
    init(url: URL) async throws
}

public enum MediaFileType {
    case image
    case video
    case audio
}
