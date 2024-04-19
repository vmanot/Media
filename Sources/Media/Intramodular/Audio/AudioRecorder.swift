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
        let newURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")

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
    @MainActor
    public func prepare() async throws {
        guard state != .prepared else {
            return
        }
                
        let url = temporaryFileURL()
        
        recording = MediaAssetLocation(url)
        
        self._base = try AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
        
        try base.delegate = self
        try base.isMeteringEnabled = true
        
        self.state = .preparing
        
        await Task.yield()
        
        try base.prepareToRecord()
        
        self.state = .prepared
    }
    
    @MainActor
    public func record() async throws {
        switch state {
            case .unprepared, .preparing:
                try await prepare()
            default:
                break
        }
        
        try _AVAudioSession.shared.setCategory(.record, mode: .default)
        try _AVAudioSession.shared.setActive(true)
        
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
        try _AVAudioSession.shared.setActive(false)
        
        do {
            try self.base.stop()
        } catch {
            do {
                try self.base.stop()
            } catch {
                throw error
            }
        }
        
        let audio = try self.recording.unwrap()
        
        let result = MediaAssetLocation.data(
            try audio.data(),
            fileTypeHint: audio.fileTypeHint
        )
        
        self.recording = result
        
        self.state = .unprepared
        
        try await prepare()
        
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
        Task { @MainActor in
            state = .stopped
        }
    }
    
    public func audioRecorderEndInterruption(
        _ recorder: AVAudioRecorder,
        withOptions flags: Int
    ) {
        Task { @MainActor in
            state = .recording
        }
    }
}

#endif
