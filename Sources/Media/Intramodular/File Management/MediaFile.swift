//
//  FileDropView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import Foundation
import UniformTypeIdentifiers

public protocol MediaFile: Identifiable, Codable, Hashable {
    var id: ID { get }
    var url: URL { get }
    var name: String { get }
    var size: Double { get }
    var duration: TimeInterval { get }
    var durationFormatted: String { get }
    var sizeFormatted: String { get }
    
    init(url: URL) async throws
}

extension AudioFile: MediaFile {}
extension VideoFile: MediaFile {}
