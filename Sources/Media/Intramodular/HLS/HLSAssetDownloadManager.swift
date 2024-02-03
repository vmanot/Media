//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import FoundationX
import Merge

internal class HLSAssetDownloadManager: NSObject {
    static let shared = HLSAssetDownloadManager()
    
    @UserDefault("com.vmanot.Media.HLSAssetMap")
    var assetPathsByName: [String: String] = [:]
    
    private var session: AVAssetDownloadURLSession!
    
    let downloadDirectory = URL.homeDirectory
    
    var assets: [HLSAsset] = []
    var downloadTaskMap = [AVAssetDownloadTask: HLSAsset]()
        
    override private init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "jp.HLSion.configuration")
        
        session = AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
        
        restoreDownloadsMap()
    }
    
    func path(forName name: String) -> String? {
        assetPathsByName[name]
    }

    private func restoreDownloadsMap() {
        session.getAllTasks { tasksArray in
            Task { @MainActor in
                for task in tasksArray {
                    guard let assetDownloadTask = task as? AVAssetDownloadTask, let assetName = task.taskDescription else {
                        break
                    }
                    
                    let asset = HLSAsset(
                        asset: assetDownloadTask.urlAsset,
                        description: assetName
                    )
                    
                    self.downloadTaskMap[assetDownloadTask] = asset
                }
            }
        }
    }
}

@MainActor
extension HLSAssetDownloadManager {
    func download(
        _ asset: HLSAsset
    ) {
        guard !assetExists(forName: asset.name) else {
            return
        }
        
        print(asset.urlAsset, asset.urlAsset.url)
        
        guard let task = session.makeAssetDownloadTask(
            asset: asset.urlAsset,
            assetTitle: asset.name,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 40_000]
        ) else {
            return
        }
        
        task.taskDescription = asset.name
        
        downloadTaskMap[task] = asset
        
        asset.state = .downloading(nil)
        
        task.resume()
    }
    
    func cancelDownload(
        _ asset: HLSAsset
    ) {
        downloadTaskMap.first(where: { $1 == asset })?.key.cancel()
    }
    
    func deleteAsset(
        forName name: String
    ) throws {
        guard let relativePath = assetPathsByName[name] else {
            return
        }
        
        let localFileLocation = downloadDirectory.appendingPathComponent(relativePath)
        
        if FileManager.default.fileExists(at: localFileLocation) {
            try FileManager.default.removeItem(at: localFileLocation)
        }
        
        assets.removeAll(where: { $0.name == name })
        assetPathsByName[name] = nil
    }
    
    func assetExists(
        forName name: String
    ) -> Bool {
        guard let relativePath = assetPathsByName[name] else {
            return false
        }
        
        let filePath = downloadDirectory.appendingPathComponent(relativePath).path
        
        return FileManager.default.fileExists(atPath: filePath)
    }
}

// MARK: - Conformances

extension HLSAssetDownloadManager: AVAssetDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard
            let task = task as? AVAssetDownloadTask,
            let asset = downloadTaskMap.removeValue(forKey: task)
        else {
            return
        }
        
        Task { @MainActor in
            if let error = error as NSError? {
                runtimeIssue(error)

                switch (error.domain, error.code) {
                    case (NSURLErrorDomain, NSURLErrorCancelled):
                        guard let localFileLocation = assetPathsByName[asset.name] else {
                            return
                        }
                        
                        do {
                            let fileURL = downloadDirectory.appendingPathComponent(localFileLocation)
                            
                            try FileManager.default.removeItem(at: fileURL)
                        } catch {
                            runtimeIssue("An error occured trying to delete the contents on disk for \(asset.name): \(error)")
                        }
                    default:
                        asset.state = .failed(.init(erasing: error))
                }
            } else {
                asset.state = .downloaded
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let asset = downloadTaskMap[assetDownloadTask] else {
            return
        }
        
        assetPathsByName[asset.name] = location.relativePath
    }
    
    func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didLoad timeRange: CMTimeRange,
        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange
    ) {
        let _loadedTimeRanges = _UncheckedSendable(loadedTimeRanges)
        
        guard let asset = downloadTaskMap[assetDownloadTask] else {
            return
        }
        
        Task { @MainActor in
            asset.state = .downloading(nil)
            
            let percentComplete = _loadedTimeRanges.wrappedValue.reduce(0.0) {
                let loadedTimeRange : CMTimeRange = $1.timeRangeValue
                return $0 + CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
            }
            
            let progress = Progress(totalUnitCount: 100)
            
            progress.completedUnitCount = Int64(floor(percentComplete * 100))
            
            asset.state = .downloading(progress)
        }
    }
}
