//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)

import AVFoundation
import Foundation
import Merge
import SwiftUIX

/// A sane, modern replacement for `AVAudioRecorder`.
public final class AudioRecorder: NSObject, ObservableObject {
    public enum State: Hashable {
        case unprepared
        case preparing
        case prepared
        case recording
        case paused
        case stopped
        case finished
        case failed(AnyError?)
    }
    
    private var _base: AVAudioRecorder?
    
    public var base: AVAudioRecorder {
        get throws {
            try _base.unwrap()
        }
    }
    
    private var temporaryAssetURL: URL?
    
    public private(set) var recording: MediaAssetLocation?
    
    @Published public private(set) var state: State
    @Published public private(set) var qualityLevel: AVAudioRecorder.QualityLevel = .best
    
    public override init() {
        state = .unprepared
    }
    
    public var normalizedPowerLevel: Float {
        guard let base = _base else {
            runtimeIssue(Never.Reason.illegal)
            
            return 0
        }
        
        guard state == .recording else {
            return 0
        }
        
        base.updateMeters()
        
        let dB = base.averagePower(forChannel: 0)
        
        if dB < -60.0 || dB == 0.0 {
            return 0.0
        }
        
        return powf((powf(10.0, Float(0.05 * dB)) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0)
    }
    
    deinit {
        
    }
    
    /// Returns a new URL for the temporary file.
    private func temporaryFileURL() -> URL {
        let newURL = MediaAssetLocation.temporaryForRecording().url!
        
        if let temporaryAssetURL = temporaryAssetURL {
            if FileManager.default.fileExists(at: temporaryAssetURL) {
                do {
                    try FileManager.default.removeItem(at: temporaryAssetURL)
                } catch {
                    runtimeIssue(error)
                }
            }
        }
        
        self.temporaryAssetURL = newURL
        
        return newURL
    }
}

extension AudioRecorder {
    private func requestPermission() async throws -> Bool {
#if os(macOS)
        return true
#else
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Bool, Never>) in
            switch AVAudioSession.sharedInstance().recordPermission {
                case AVAudioSession.RecordPermission.granted:
                    continuation.resume(returning: true)
                case AVAudioSession.RecordPermission.denied:
                    continuation.resume(returning: false)
                case AVAudioSession.RecordPermission.undetermined:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                @unknown default:
                    continuation.resume(returning: false)
            }
        }
#endif
    }
    
    @MainActor
    public func prepare() async throws {
        guard state != .prepared else {
            return
        }
        
        let permitted = try await requestPermission()
        
        try _tryAssert(permitted)
        
        let url = temporaryFileURL()
        
        recording = MediaAssetLocation(url)
        
        assert(!FileManager.default.fileExists(at: url))
        
        self._base = try AVAudioRecorder(
            url: url,
            settings: AVAudioRecorder.settings(for: self.qualityLevel)
        )
        
        try base.delegate = self
        try base.isMeteringEnabled = true
        
        self.state = .preparing
        
        await Task.yield()
        
        let prepared = try await Task.detached(priority: .userInitiated) { () -> Bool in
            do {
                try _AVAudioSession.shared.setCategory(.record, mode: .default)
                try _AVAudioSession.shared.setActive(true)
                return try self.base.prepareToRecord()
            } catch {
                #if !os(macOS)
                _ = try? _AVAudioSession.shared.enableBuiltInMicIfPossible()
                #endif
                
                do {
                    try _AVAudioSession.shared.setCategory(.record, mode: .default)
                    try _AVAudioSession.shared.setActive(true)
                } catch {
                    runtimeIssue(error)
                }
                
                return try self.base.prepareToRecord()
            }
        }.value
        
        guard prepared else {
            throw _PlaceholderError()
        }
        
        self.state = .prepared
    }
    
    @MainActor
    public func record() async throws {
        switch state {
            case .unprepared, .stopped, .finished, .failed:
                try await prepare()
            default:
                break
        }
        
        do {
            try base.record()
        } catch {
            do {
                try base.prepareToRecord()
                try await Task.sleep(.milliseconds(100))
                try base.record()
            } catch {
                throw _PlaceholderError()
            }
        }
        
        self.state = .recording
    }
    
    @MainActor
    public func pause() async throws {
        try self.base.pause()
        
        self.state = .paused
    }
    
    @discardableResult
    @MainActor
    public func stop() async throws -> MediaAssetLocation {
        
        do {
            try _AVAudioSession.shared.setActive(false)
            try self.base.stop()
        } catch {
            do {
                try _AVAudioSession.shared.setActive(false)
                try self.base.stop()
            } catch {
                throw error
            }
        }
        
        let audio = try self.recording.unwrap()
        let recordingData: Data = try audio.data()
        
        let result = MediaAssetLocation.data(
            recordingData,
            fileTypeHint: audio.fileTypeHint
        )
        
        self.recording = result
        
        self.state = .stopped
            
        return result
    }
    
    public func toggleRecordPause() async throws {
        switch state {
            case .unprepared, .prepared, .preparing:
                return try await record()
            case .recording:
                return try await pause()
            case .paused:
                return try await record()
            case .stopped, .finished, .failed:
                return try await record()
        }
    }
}

// MARK: - Conformances

extension AudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            if flag {
                state = .finished
            } else {
                state = .failed(nil)
            }
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(
        _ recorder: AVAudioRecorder,
        error: Error?
    ) {
        Task { @MainActor in
            state = .failed(error.map({ AnyError(erasing: $0) }))
        }
    }
    
    public func audioRecorderBeginInterruption(
        _ recorder: AVAudioRecorder
    ) {
        
    }
    
    public func audioRecorderEndInterruption(
        _ recorder: AVAudioRecorder,
        withOptions flags: Int
    ) {
        
    }
}

#endif
