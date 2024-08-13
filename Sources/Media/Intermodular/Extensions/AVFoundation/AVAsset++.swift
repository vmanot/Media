//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import Swallow

extension AVAsset {
    func convert(
        to outputFormat: AudioFileFormatType,
        outputURL: URL
    ) async throws {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetPassthrough) else {
            throw ConversionError.exportSessionFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = try outputFormat._toAVFileType()
        
        let _exportSession = _UncheckedSendable(exportSession)
        
        return try await withUnsafeThrowingContinuation { continuation in
            _exportSession.wrappedValue.exportAsynchronously {
                switch _exportSession.wrappedValue.status {
                    case .completed:
                        continuation.resume()
                    case .failed:
                        continuation.resume(throwing: ConversionError.exportFailed)
                    case .cancelled:
                        continuation.resume(throwing: ConversionError.exportCancelled)
                    default:
                        break
                }
            }
        }
    }
    
    private enum ConversionError: Error {
        case exportSessionFailed
        case exportFailed
        case exportCancelled
    }
}
