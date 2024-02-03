//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import FoundationX
import Merge

@MainActor
public class HLSAsset: ObservableObject {
    public enum State: Equatable {
        case notDownloaded
        case downloading(Progress?)
        case downloaded
        case failed(AnyError)
        
        public var isDownloading: Bool {
            guard case .downloaded = self else {
                return false
            }
            
            return true
        }
    }
    
    public let name: String
    public let urlAsset: AVURLAsset
    
    @Published public internal(set) var state: State = .notDownloaded
    
    internal var resolvedMediaSelection: AVMediaSelection?
            
    internal init(
        asset: AVURLAsset,
        description: String
    ) {
        name = description
        urlAsset = asset
        
        _state = .init(
            wrappedValue: HLSAssetDownloadManager.shared.assetExists(forName: name) ? .downloaded : .notDownloaded
        )
    }
    
    @MainActor
    public static func asset(
        url: URL,
        options: [String: Any]? = nil,
        name: String
    ) -> HLSAsset {
        let allAssets = Array(HLSAssetDownloadManager.shared.downloadTaskMap.values) + HLSAssetDownloadManager.shared.assets
        
        if let asset = allAssets.first(where: { asset -> Bool in
            return asset.urlAsset.url == url && asset.name == name
        }) {
            return asset
        }
            
        let urlAsset = AVURLAsset(url: url, options: options)
        let state: State = HLSAssetDownloadManager.shared.assetExists(forName: name) ? .downloaded : .notDownloaded
        let result = HLSAsset(asset: urlAsset, description: name)
        
        result.state = state
        
        HLSAssetDownloadManager.shared.assets.append(result)
        
        return result
    }
}

extension HLSAsset {
    public func download() {
        HLSAssetDownloadManager.shared.download(self)
    }
            
    public func cancelDownload() {
        HLSAssetDownloadManager.shared.cancelDownload(self)
    }
    
    public func delete() throws {
        do {
            try HLSAssetDownloadManager.shared.deleteAsset(forName: name)
        } catch {
            runtimeIssue(error)
        }
        
        self.state = .notDownloaded
    }
}

extension HLSAsset {
    public var progress: Progress? {
        guard case .downloading(let progress) = state else {
            return nil
        }
        
        return progress
    }
    
    public var url: URL? {
        guard let relativePath = HLSAssetDownloadManager.shared.path(forName: name) else {
            return nil
        }
        
        return HLSAssetDownloadManager.shared.downloadDirectory.appendingPathComponent(relativePath)
    }

    public var offlineAssetSize: UInt64? {
        guard state == .downloaded else {
            return nil
        }
        
        guard let relativePath = HLSAssetDownloadManager.shared.path(forName: name) else {
            return nil
        }
        
        let bundleURL = HLSAssetDownloadManager.shared.downloadDirectory.appendingPathComponent(relativePath)
        
        guard let subpaths = try? FileManager.default.subpathsOfDirectory(atPath: bundleURL.path) else {
            return 0
        }
        
        let size: UInt64 = subpaths.reduce(0) {
            let filePath = bundleURL.appendingPathComponent($1).path
            
            guard let fileAttribute = try? FileManager.default.attributesOfItem(atPath: filePath) else {
                return $0
            }
            
            guard let size = fileAttribute[FileAttributeKey.size] as? NSNumber else {
                return $0
            }
            
            return $0 + size.uint64Value
        }
        
        return size
    }
}

// MARK: - Conformances

extension HLSAsset: CustomStringConvertible {
    public var description: String {
        return "\(name), \(urlAsset.url)"
    }
}

extension HLSAsset: Equatable {
    public static func == (lhs: HLSAsset, rhs: HLSAsset) -> Bool {
        return (lhs.name == rhs.name) && (lhs.urlAsset == rhs.urlAsset)
    }
}
