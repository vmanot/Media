//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)

import AVFoundation
import SwiftUIX

extension AVAudioRecorder {
    public enum QualityLevel: String {
        case low
        case medium
        case high
        case best
    }
    
    public static func settings(
        for qualityLevel: QualityLevel
    ) -> [String: Any] {
        var settings: [String: Any] = [:]
                
        // Determine the sample rate based on quality level
        var sampleRate = 44100.0
        
        switch qualityLevel {
            case .low:
                sampleRate = 22050.0
            case .medium:
                sampleRate = 44100.0
            case .high, .best:
                #if !os(macOS)
                let preferredSampleRate = AVAudioSession.sharedInstance().sampleRate
                
                if preferredSampleRate > 0 {
                    sampleRate = preferredSampleRate
                }
                #endif
        }
        
        // Determine the audio format based on quality level and platform
        var audioFormat = Int(kAudioFormatLinearPCM)
        
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *), !isRunningInSimulator() {
            audioFormat = Int(kAudioFormatLinearPCM)
            // audioFormat = Int(kAudioFormatMPEG4AAC)
        }
        
        // Determine the bit depth based on quality level
        var bitDepth = 16
        switch qualityLevel {
            case .low, .medium:
                bitDepth = 16
            case .high, .best:
                break
        }
        
        // Set the audio settings
        settings[AVFormatIDKey] = audioFormat
        settings[AVSampleRateKey] = sampleRate
        settings[AVNumberOfChannelsKey] = 1
        settings[AVEncoderBitRateKey] = bitRateForQualityLevel(qualityLevel)
        settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue
        
        if audioFormat == Int(kAudioFormatLinearPCM) {
            settings[AVLinearPCMBitDepthKey] = bitDepth
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsFloatKey] = bitDepth == 32
        }
        
        if isRunningInSimulator() {
            settings = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatAppleIMA4)
            settings[AVSampleRateKey] = 44100
            settings[AVNumberOfChannelsKey] = 2
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.medium
            settings[AVLinearPCMIsNonInterleaved] = false
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
        }
        
        return settings
    }
    
    private static func bitRateForQualityLevel(_ qualityLevel: QualityLevel) -> Int {
        switch qualityLevel {
            case .low:
                return 64000
            case .medium:
                return 128000
            case .high:
                return 192000
            case .best:
                return 320000
        }
    }
    
    private static func isRunningInSimulator() -> Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
}

#endif
