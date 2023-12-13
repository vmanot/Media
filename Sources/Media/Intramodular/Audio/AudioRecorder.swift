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
    public enum State {
        case unprepared
        case prepared
        case recording
        case paused
        case stopped
    }
    
    private var _base: AVAudioRecorder?
    
    public var base: AVAudioRecorder {
        get throws {
            try _base.unwrap()
        }
    }
    
    private var recordingLocationURL: URL?
    
    public private(set) var recording: MediaAssetLocation?
    
    public override init() {
        state = .unprepared
    }
    
    @Published public private(set) var state: State
    
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
        if let recordingLocationURL = recordingLocationURL {
            do {
                try FileManager.default.removeItem(at: recordingLocationURL)
            } catch {
                fatalError()
            }
        }
    }
}

extension AudioRecorder {
    @MainActor
    public func prepare() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        recording = .init(url)
        
        self._base = try AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
        
        try base.delegate = self
        try base.isMeteringEnabled = true
        try base.prepareToRecord()
        
        self.state = .prepared
    }
    
    @MainActor
    public func record() async throws {
        try _AVAudioSession.shared.setCategory(.record, mode: .default)
        try _AVAudioSession.shared.setActive(true)
        
        guard try base.record() else {
            throw _PlaceholderError()
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

        try self.base.stop()
        
        let audio = try self.recording.unwrap()

        let result = MediaAssetLocation.data(
            try audio.data(),
            fileTypeHint: audio.fileTypeHint
        )
        
        self.recording = result
        
        self.state = .stopped
        
        return result
    }
    
    public func toggleRecordPause() async throws {
        switch state {
            case .unprepared, .prepared:
                return try await record()
            case .recording:
                return try await pause()
            case .paused:
                return try await record()
            case .stopped:
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
        
    }
    
    public func audioRecorderEncodeErrorDidOccur(
        _ recorder: AVAudioRecorder,
        error: Error?
    ) {
        
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
