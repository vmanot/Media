//
//  ImageFile.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import AVFoundation
import CoreTransferable
import SwiftUI

public struct ImageFile: MediaFile {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    public let id: ID
    public let url: URL
    public let name: String
    public let size: Double
    public let dimensions: CGSize
    public let format: ImageFileFormatType
    public var metadata: [String: AnyCodable]
    
    public var sizeFormatted: String {
        String(format: "%.1f MB", size)
    }
    
    public var dimensionsFormatted: String {
        "\(Int(dimensions.width))×\(Int(dimensions.height))"
    }
    
    public init(url: URL) async throws {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Double(resourceValues.fileSize ?? 0) / (1024 * 1024)
        
        guard let imageSource = CGImageSource.create(with: url),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat else {
            throw ImageFileError.failedToLoadImage
        }
        
        let format: ImageFileFormatType
        if let utType = CGImageSourceGetType(imageSource) as String? {
            switch utType {
            case UTType.jpeg.identifier:
                format = .jpeg
            case UTType.png.identifier:
                format = .png
            case UTType.heic.identifier:
                format = .heic
            default:
                format = .jpeg
            }
        } else {
            format = .jpeg
        }
        
        self.id = .random()
        self.url = url
        self.name = url.lastPathComponent
        self.size = fileSize
        self.dimensions = CGSize(width: width, height: height)
        self.format = format
        self.metadata = [:]
    }
}

// MARK: - Conformances

extension ImageFile: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .image)
        
        FileRepresentation(contentType: .image) { imageFile in
            SentTransferredFile(imageFile.url)
        } importing: { received in
            let url = received.file
            return try await ImageFile(url: url)
        }
        
        ProxyRepresentation(exporting: \.url)
        
        DataRepresentation(contentType: .image) { imageFile in
            try Data(contentsOf: imageFile.url)
        } importing: { data in
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpeg")
            
            try data.write(to: temporaryURL)
            return try await ImageFile(url: temporaryURL)
        }
    }
}

// MARK: - Error Handling

public enum ImageFileError: LocalizedError {
    case invalidURL
    case failedToLoadImage
    case failedToGetFileSize
    case failedToDeleteFile
    case fileNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .failedToLoadImage:
            return "Failed to load image"
        case .failedToGetFileSize:
            return "Failed to get image file size"
        case .failedToDeleteFile:
            return "Failed to delete image file"
        case .fileNotFound:
            return "Image file not found"
        }
    }
}

// MARK: - Helper Extension

extension CGImageSource {
    static func create(with url: URL) -> CGImageSource? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return CGImageSourceCreateWithData(data as CFData, nil)
    }
}
