//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || targetEnvironment(macCatalyst)

import AVFoundation
import Foundation
import Merge
import SwiftUIX

public final class AudioRecorder: NSObject, ObservableObject {
    public enum State {
        case unprepared
        case prepared
        case recording
        case paused
        case stopped
    }
    
    private var base: AVAudioRecorder?
    private var recordingLocationURL: URL?
    
    public private(set) var recording: MediaAssetLocation?
    
    public override init() {
        state = .unprepared
    }
    
    @Published public private(set) var state: State
    
    public var normalizedPowerLevel: Float {
        guard let base = base else {
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

extension AudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        
    }
    
    public func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {
        
    }
    
    public func audioRecorderEndInterruption(_ recorder: AVAudioRecorder, withOptions flags: Int) {
        
    }
}

extension AudioRecorder {
    public func prepare() -> AnySingleOutputPublisher<Void, Error> {
        Future.perform { [self] in
            recordingLocationURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            recording = .init(try recordingLocationURL.unwrap())
            
            base = try AVAudioRecorder(url: try recordingLocationURL.unwrap(), settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            
            try base.unwrap().delegate = self
            try base.unwrap().isMeteringEnabled = true
            try base.unwrap().prepareToRecord()
        }
        .then(on: DispatchQueue.main) {
            self.state = .prepared
        }
        .eraseToAnySingleOutputPublisher()
    }
    
    public func record() -> AnySingleOutputPublisher<Void, Error> {
        prepare()
            .tryMap {
                try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                try self.base.unwrap().record()
            }
            .then(on: DispatchQueue.main) {
                self.state = .recording
            }
            .eraseToAnySingleOutputPublisher()
    }
    
    public func pause() -> AnySingleOutputPublisher<Void, Error> {
        Future.perform {
            try self.base.unwrap().pause()
        }
        .then(on: DispatchQueue.main) {
            self.state = .paused
        }
        .eraseToAnySingleOutputPublisher()
    }
    
    public func stop() -> AnySingleOutputPublisher<Void, Error> {
        Future<Void, Error>.perform(on: DispatchQueue.global(qos: .userInitiated)) {
            try self.base.unwrap().stop()
            
            self.recording = .data(try self.recording.unwrap().data())
        }
        .then(on: DispatchQueue.main) {
            self.state = .stopped
        }
        .eraseToAnySingleOutputPublisher()
    }
    
    public func toggleRecordPause() -> AnySingleOutputPublisher<Void, Error> {
        switch state {
            case .unprepared, .prepared:
                return record()
            case .recording:
                return pause()
            case .paused:
                return record()
            case .stopped:
                return record()
        }
    }
}

#endif
